import { describe, test, expect } from 'bun:test';
import { generateUUIDv7, generatePIN, isValidUUIDv7, isValidPIN } from '../../src/utils/idGenerator';

describe('ID Generator', () => {
  describe('generateUUIDv7', () => {
    test('should generate a valid UUIDv7', () => {
      const uuid = generateUUIDv7();
      expect(isValidUUIDv7(uuid)).toBe(true);
    });

    test('should generate unique UUIDs', () => {
      const uuid1 = generateUUIDv7();
      const uuid2 = generateUUIDv7();
      expect(uuid1).not.toBe(uuid2);
    });

    test('should have version 7 in the correct position', () => {
      const uuid = generateUUIDv7();
      const versionChar = uuid.charAt(14);
      expect(versionChar).toBe('7');
    });

    test('should be time-ordered', async () => {
      const uuid1 = generateUUIDv7();
      // Wait 1ms to ensure different timestamp
      await new Promise(resolve => setTimeout(resolve, 1));
      const uuid2 = generateUUIDv7();
      // UUIDv7 should be lexicographically sortable by time
      expect(uuid1 < uuid2).toBe(true);
    });
  });

  describe('generatePIN', () => {
    test('should generate a 6-digit PIN', () => {
      const pin = generatePIN();
      expect(isValidPIN(pin)).toBe(true);
      expect(pin.length).toBe(6);
    });

    test('should generate numeric PINs', () => {
      const pin = generatePIN();
      expect(/^\d+$/.test(pin)).toBe(true);
    });

    test('should generate PINs in valid range', () => {
      const pin = generatePIN();
      const pinNum = parseInt(pin, 10);
      expect(pinNum).toBeGreaterThanOrEqual(100000);
      expect(pinNum).toBeLessThan(1000000);
    });

    test('should generate different PINs', () => {
      const pin1 = generatePIN();
      const pin2 = generatePIN();
      // While theoretically they could be the same, probability is very low
      // This test may occasionally fail but validates randomness
      const pins = new Set();
      for (let i = 0; i < 100; i++) {
        pins.add(generatePIN());
      }
      expect(pins.size).toBeGreaterThan(90); // At least 90% unique
    });
  });

  describe('isValidUUIDv7', () => {
    test('should validate correct UUIDv7 format', () => {
      const uuid = generateUUIDv7();
      expect(isValidUUIDv7(uuid)).toBe(true);
    });

    test('should reject invalid UUID formats', () => {
      expect(isValidUUIDv7('invalid')).toBe(false);
      expect(isValidUUIDv7('12345678-1234-1234-1234-123456789012')).toBe(false);
      expect(isValidUUIDv7('12345678-1234-4234-1234-123456789012')).toBe(false); // v4, not v7
    });
  });

  describe('isValidPIN', () => {
    test('should validate correct PIN format', () => {
      expect(isValidPIN('123456')).toBe(true);
      expect(isValidPIN('000000')).toBe(true);
      expect(isValidPIN('999999')).toBe(true);
    });

    test('should reject invalid PIN formats', () => {
      expect(isValidPIN('12345')).toBe(false); // Too short
      expect(isValidPIN('1234567')).toBe(false); // Too long
      expect(isValidPIN('12345a')).toBe(false); // Contains letter
      expect(isValidPIN('abc123')).toBe(false); // Contains letters
    });
  });
});
