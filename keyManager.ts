
import * as crypto from 'crypto';

class KeyManager {
    private keys: Map<string, string>;

    constructor() {
        this.keys = new Map();
    }

    generateKey(keyName: string): string {
        const key = crypto.randomBytes(32).toString('hex');
        this.keys.set(keyName, key);
        return key;
    }

    getKey(keyName: string): string | undefined {
        return this.keys.get(keyName);
    }

    deleteKey(keyName: string): boolean {
        return this.keys.delete(keyName);
    }
}

export default KeyManager;
