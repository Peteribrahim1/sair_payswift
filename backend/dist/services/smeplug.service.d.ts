export declare const SMEPLUG_NETWORK_IDS: Record<string, number>;
/**
 * Fetch all data plans for a given network from SMEPlug.
 * Returns only plans that have a valid price > 0.
 */
export declare function smeplugGetDataPlans(networkId: number): Promise<any[]>;
/**
 * Purchase a data plan from SMEPlug.
 * Returns the transaction reference and status.
 */
export declare function smeplugBuyData(networkId: number, planId: number, phone: string, reference: string): Promise<{
    reference: string;
    status: string;
}>;
