import crypto from 'crypto';

/**
 * Generates a UUIDv7 (time-ordered UUID)
 * Format: xxxxxxxx-xxxx-7xxx-xxxx-xxxxxxxxxxxx
 * First 48 bits: Unix timestamp in milliseconds
 * Version bits: 0111 (7)
 * Variant bits: 10
 * Remaining bits: Random
 */
export function generateUUIDv7(): string {
  const timestamp = BigInt(Date.now());
  
  // Get random bytes for the UUID
  const randomBytes = crypto.randomBytes(10);
  
  // Create timestamp bytes (48 bits = 6 bytes)
  const timestampHex = timestamp.toString(16).padStart(12, '0');
  
  // Parse timestamp into bytes
  const timestampBytes = Buffer.from(timestampHex, 'hex');
  
  // Build UUID parts
  const timeLow = timestampBytes.subarray(0, 4).toString('hex');
  const timeMid = timestampBytes.subarray(4, 6).toString('hex');
  
  // Version 7: Set version bits (4 bits) to 0111
  const timeHiAndVersion = ((randomBytes[0]! & 0x0f) | 0x70).toString(16).padStart(2, '0') + 
                           randomBytes[1]!.toString(16).padStart(2, '0');
  
  // Variant: Set variant bits (2 bits) to 10
  const clockSeqAndVariant = ((randomBytes[2]! & 0x3f) | 0x80).toString(16).padStart(2, '0') + 
                             randomBytes[3]!.toString(16).padStart(2, '0');
  
  // Node: Remaining random bytes
  const node = randomBytes.subarray(4, 10).toString('hex');
  
  return `${timeLow}-${timeMid}-${timeHiAndVersion}-${clockSeqAndVariant}-${node}`;
}

/**
 * Generates a unique 6-digit PIN
 * Note: Uniqueness within organization must be validated by the caller
 * @returns A 6-digit PIN as a string
 */
export function generatePIN(): string {
  // Generate a random 6-digit number (100000 to 999999)
  const pin = crypto.randomInt(100000, 1000000);
  return pin.toString();
}

/**
 * Validates if a string is a valid UUIDv7 format
 */
export function isValidUUIDv7(uuid: string): boolean {
  const uuidv7Regex = /^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidv7Regex.test(uuid);
}

/**
 * Validates if a string is a valid PIN format (6 digits)
 */
export function isValidPIN(pin: string): boolean {
  return /^\d{6}$/.test(pin);
}
