import { parsePhoneNumberWithError } from 'libphonenumber-js';
import { BadRequestException } from '@nestjs/common';

export function normalizePhone(phone: string): string {
  try {
    // Attempt to parse. Defaulting to IN (India) if no country code provided,
    // though E.164 strings typically include the country code (e.g. +91).
    const phoneNumber = parsePhoneNumberWithError(phone, 'IN');
    if (!phoneNumber.isValid()) {
      throw new BadRequestException('Invalid phone number format');
    }
    return phoneNumber.number.toString(); // E.164 format
  } catch (error) {
    if (error instanceof BadRequestException) {
      throw error;
    }
    throw new BadRequestException('Invalid phone number format');
  }
}
