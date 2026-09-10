/*
  Warnings:

  - Added the required column `updated_at` to the `daily_reviews` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "daily_reviews" ADD COLUMN     "updated_at" TIMESTAMPTZ(6) NOT NULL;
