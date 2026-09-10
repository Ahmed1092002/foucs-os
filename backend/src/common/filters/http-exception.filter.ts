import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

interface ErrorEnvelope {
  code: string;
  message: string;
  details?: unknown;
}

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let envelope: ErrorEnvelope = {
      code: 'INTERNAL',
      message: 'Unexpected server error',
    };

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const body = exception.getResponse();
      envelope = this.fromHttpException(status, body);
    } else if (exception instanceof Error) {
      this.logger.error(`${request.method} ${request.url} → ${exception.message}`, exception.stack);
    } else {
      this.logger.error(`${request.method} ${request.url} → ${String(exception)}`);
    }

    response.status(status).json({
      ...envelope,
      path: request.url,
      method: request.method,
      timestamp: new Date().toISOString(),
    });
  }

  private fromHttpException(status: number, body: unknown): ErrorEnvelope {
    const code = this.codeForStatus(status);
    if (typeof body === 'string') {
      return { code, message: body };
    }
    if (typeof body === 'object' && body !== null) {
      const obj = body as Record<string, unknown>;
      return {
        code,
        message: typeof obj.message === 'string' ? obj.message : code,
        details: obj.message instanceof Array ? obj.message : obj.details,
      };
    }
    return { code, message: code };
  }

  private codeForStatus(status: number): string {
    switch (status) {
      case 400: return 'VALIDATION_ERROR';
      case 401: return 'UNAUTHENTICATED';
      case 403: return 'FORBIDDEN';
      case 404: return 'NOT_FOUND';
      case 409: return 'CONFLICT';
      case 429: return 'RATE_LIMITED';
      default: return status >= 500 ? 'INTERNAL' : 'ERROR';
    }
  }
}