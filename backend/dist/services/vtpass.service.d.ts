export declare const AIRTIME_SERVICE_IDS: Record<string, string>;
export declare const DATA_SERVICE_IDS: Record<string, string>;
export declare const ELECTRICITY_SERVICE_IDS: Record<string, string>;
export declare const CABLE_SERVICE_IDS: Record<string, string>;
/** Buy airtime — MTN, Airtel, Glo, 9mobile */
export declare function vtpassBuyAirtime(serviceID: string, phone: string, amount: number): Promise<{
    requestId: string;
    response: any;
}>;
/** Fetch live data variation codes for a network */
export declare function vtpassGetDataVariations(serviceID: string): Promise<any[]>;
/** Buy mobile data — MTN, Airtel, Glo, 9mobile */
export declare function vtpassBuyData(serviceID: string, phone: string, variationCode: string, amount: number): Promise<{
    requestId: string;
    response: any;
}>;
/** Pay electricity bill */
export declare function vtpassPayElectricity(serviceID: string, meterNumber: string, variationCode: 'prepaid' | 'postpaid', amount: number, phone: string): Promise<{
    requestId: string;
    response: any;
}>;
/** Fetch cable TV variation codes (subscription plans) */
export declare function vtpassGetCablePlans(serviceID: string): Promise<any[]>;
/** Verify smart card / IUC number before payment */
export declare function vtpassVerifySmartCard(serviceID: string, smartCardNumber: string): Promise<any>;
/** Pay cable TV (DSTV, GOTV, StarTimes, Showmax) */
export declare function vtpassPayCableTV(serviceID: string, smartCardNumber: string, variationCode: string, amount: number, phone: string): Promise<{
    requestId: string;
    response: any;
}>;
/** Requery a transaction by request_id (for dispute/status check) */
export declare function vtpassRequery(requestId: string): Promise<any>;
