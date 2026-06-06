export declare function createCustomer(email: string, firstName: string, lastName: string, phone?: string): Promise<{
    customerCode: string;
}>;
export declare function validateCustomerKYC(customerCode: string, firstName: string, lastName: string, bvn?: string, nin?: string): Promise<boolean>;
export declare function createDVA(customerCode: string, customerName?: string): Promise<{
    accountNumber: string;
    bankName: string;
    accountName: string;
}>;
export declare function fetchDVA(customerCode: string): Promise<{
    accountNumber: string;
    bankName: string;
    accountName: string;
} | null>;
export declare function verifyWebhookSignature(rawBody: string, signatureHeader: string): boolean;
export declare function fetchBanks(): Promise<any[]>;
export declare function verifyAccountNumber(accountNumber: string, bankCode: string): Promise<string>;
export declare function createTransferRecipient(name: string, accountNumber: string, bankCode: string): Promise<string>;
export declare function initiateTransfer(amountNaira: number, recipientCode: string, reference?: string): Promise<any>;
