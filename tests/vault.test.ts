import { describe, it, expect, beforeEach } from "vitest";

type Principal = string;

interface VaultMock {
  admin: Principal;
  auditor: Principal;
  paused: boolean;
  balances: Map<string, bigint>;
  dailyWithdrawals: Map<string, bigint>;
  allowedTokens: Set<Principal>;
  collectedFees: bigint;
  depositFeeBps: bigint;
  withdrawFeeBps: bigint;
  dailyLimit: bigint;

  deposit(user: Principal, token: Principal, amount: bigint): any;
  withdraw(user: Principal, token: Principal, amount: bigint): any;
  whitelistToken(caller: Principal, token: Principal, status: boolean): any;
  pause(caller: Principal, pause: boolean): any;
  setFees(caller: Principal, dep: bigint, wit: bigint): any;
  resetDailyWithdrawals(caller: Principal, user: Principal, token: Principal): any;
}

const vault: VaultMock = {
  admin: "STADMIN",
  auditor: "STAUDITOR",
  paused: false,
  balances: new Map(),
  dailyWithdrawals: new Map(),
  allowedTokens: new Set(),
  collectedFees: 0n,
  depositFeeBps: 10n,
  withdrawFeeBps: 20n,
  dailyLimit: 10000n,

  deposit(user, token, amount) {
    if (!this.allowedTokens.has(token)) return { error: 101 };
    if (amount <= 0n) return { error: 105 };
    if (this.paused) return { error: 104 };
    const fee = (amount * this.depositFeeBps) / 10000n;
    const key = `${user}-${token}`;
    this.balances.set(key, (this.balances.get(key) || 0n) + (amount - fee));
    this.collectedFees += fee;
    return { value: true };
  },

  withdraw(user, token, amount) {
    if (!this.allowedTokens.has(token)) return { error: 101 };
    if (amount <= 0n) return { error: 105 };
    if (this.paused) return { error: 104 };

    const key = `${user}-${token}`;
    const bal = this.balances.get(key) || 0n;
    if (bal < amount) return { error: 102 };

    const wdKey = `${user}-${token}-day`;
    const withdrawnToday = this.dailyWithdrawals.get(wdKey) || 0n;
    if (withdrawnToday + amount > this.dailyLimit) return { error: 103 };

    const fee = (amount * this.withdrawFeeBps) / 10000n;
    this.balances.set(key, bal - amount);
    this.dailyWithdrawals.set(wdKey, withdrawnToday + amount);
    this.collectedFees += fee;
    return { value: { netAmount: amount - fee } };
  },

  whitelistToken(caller, token, status) {
    if (caller !== this.admin) return { error: 100 };
    if (status) this.allowedTokens.add(token);
    else this.allowedTokens.delete(token);
    return { value: status };
  },

  pause(caller, pause) {
    if (caller !== this.admin) return { error: 100 };
    this.paused = pause;
    return { value: pause };
  },

  setFees(caller, dep, wit) {
    if (caller !== this.admin) return { error: 100 };
    this.depositFeeBps = dep;
    this.withdrawFeeBps = wit;
    return { value: true };
  },

  resetDailyWithdrawals(caller, user, token) {
    if (caller !== this.auditor) return { error: 100 };
    const wdKey = `${user}-${token}-day`;
    this.dailyWithdrawals.delete(wdKey);
    return { value: true };
  },
};

describe("Stablecoin Vault Contract", () => {
  const ALICE = "STALICE";
  const USDC = "STUSDC";

  beforeEach(() => {
    vault.balances.clear();
    vault.dailyWithdrawals.clear();
    vault.allowedTokens.clear();
    vault.collectedFees = 0n;
    vault.depositFeeBps = 10n;
    vault.withdrawFeeBps = 20n;
    vault.paused = false;
  });

  it("should allow admin to whitelist token", () => {
    const result = vault.whitelistToken(vault.admin, USDC, true);
    expect(result).toEqual({ value: true });
    expect(vault.allowedTokens.has(USDC)).toBe(true);
  });

  it("should deposit tokens with fee", () => {
    vault.whitelistToken(vault.admin, USDC, true);
    const result = vault.deposit(ALICE, USDC, 10000n);
    expect(result).toEqual({ value: true });
    expect(vault.balances.get(`${ALICE}-${USDC}`)).toBe(9990n); // fee deducted
    expect(vault.collectedFees).toBe(10n);
  });

    it("should withdraw tokens with fee", () => {
    vault.whitelistToken(vault.admin, USDC, true);
    vault.deposit(ALICE, USDC, 20000n);
    const result = vault.withdraw(ALICE, USDC, 10000n);
    expect(result.value.netAmount).toBe(9980n);
    expect(vault.balances.get(`${ALICE}-${USDC}`)).toBe(9980n);
    expect(vault.collectedFees).toBeGreaterThan(0n);
    });

  it("should enforce daily withdrawal limit", () => {
    vault.whitelistToken(vault.admin, USDC, true);
    vault.deposit(ALICE, USDC, 20000n);
    const result1 = vault.withdraw(ALICE, USDC, 8000n);
    expect(result1.value.netAmount).toBeLessThan(8000n);
    const result2 = vault.withdraw(ALICE, USDC, 3000n);
    expect(result2).toEqual({ error: 103 });
  });

  it("should allow auditor to reset daily withdrawals", () => {
    vault.whitelistToken(vault.admin, USDC, true);
    vault.deposit(ALICE, USDC, 20000n);
    vault.withdraw(ALICE, USDC, 8000n);
    const reset = vault.resetDailyWithdrawals(vault.auditor, ALICE, USDC);
    expect(reset).toEqual({ value: true });
    const result2 = vault.withdraw(ALICE, USDC, 3000n);
    expect(result2.value.netAmount).toBeGreaterThan(0n);
  });

  it("should prevent deposits or withdrawals when paused", () => {
    vault.whitelistToken(vault.admin, USDC, true);
    vault.pause(vault.admin, true);
    const dep = vault.deposit(ALICE, USDC, 1000n);
    expect(dep).toEqual({ error: 104 });
    const wit = vault.withdraw(ALICE, USDC, 1000n);
    expect(wit).toEqual({ error: 104 });
  });

  it("should allow admin to set different fees", () => {
    const result = vault.setFees(vault.admin, 50n, 100n);
    expect(result).toEqual({ value: true });
    expect(vault.depositFeeBps).toBe(50n);
    expect(vault.withdrawFeeBps).toBe(100n);
  });
});
