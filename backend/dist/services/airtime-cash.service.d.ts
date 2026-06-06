export declare class AirtimeCashService {
    /**
     * Mocks initializing an Airtime to Cash transaction with a 3rd party provider.
     */
    static initializeConversion(amount: number, network: string, phone: string, userId: string): Promise<any>;
    /**
     * Handles the webhook callback from the 3rd party provider
     */
    static handleWebhook(payload: any): Promise<{
        success: boolean;
        message: string;
    } | {
        success: boolean;
        message?: undefined;
    }>;
}
