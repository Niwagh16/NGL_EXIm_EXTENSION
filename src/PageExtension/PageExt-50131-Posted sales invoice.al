pageextension 50131 Posted_Sales_Inv_Ext extends "Posted Sales Invoice"
{
    layout
    {
        addafter(SalesInvLines)
        {
            part("E-Way Bill Detail"; 50106)
            {
                SubPageLink = "Document No." = FIELD("No.");
            }
        }
        addbefore("Foreign Trade")
        {
            group("E-Invoice Details")
            {
                part("E-Invoice Detail"; 50105)
                {
                    SubPageLink = "Document No." = FIELD("No.");
                }
            }
        }
    }

    actions
    {
        addafter(IncomingDocAttachFile)
        {
            action("Generate E-InvoicePCPL")
            {
                Enabled = EINVGen;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction();
                begin
                    //PCPL41-EINV
                    GenerateEInvoice;
                    //PCPL41-EINV
                end;
            }
            action("Cancel E-InvoicePCPL")
            {
                Enabled = EINVCan;
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction();
                begin
                    //PCPL41-EINV
                    CancelEInvoice;
                    //PCPL41-EINV
                end;
            }
            action("Generate E-Way Bill")
            {
                Visible = true;

                trigger OnAction();
                var
                    SalesPost: Codeunit 80;
                begin
                    //PCPL41-EWAY
                    TESTFIELD("Vehicle No.");
                    IF NOT CONFIRM('Do you want generate E-Way Bill?') THEN
                        EXIT;
                    IF Rec."E-Way Bill Generate" = Rec."E-Way Bill Generate"::"To Generate" THEN
                        Ewaybill_returnV(Rec)
                    ELSE
                        ERROR('E-way Bill Generate should be "To Generate".');
                    //PCPL41-EWAY
                end;
            }
            action("Generate E-Way Bill - Testing")
            {

                trigger OnAction();
                var
                    SalesPost: Codeunit 80;
                begin
                    TESTFIELD("Vehicle No.");
                    //PCPL41-EWAY
                    IF NOT CONFIRM('Do you want generate E-Way Bill?') THEN
                        EXIT;
                    IF Rec."E-Way Bill Generate" = Rec."E-Way Bill Generate"::"To Generate" THEN
                        Ewaybill_returnV_Test(Rec)
                    ELSE
                        ERROR('E-way Bill Generate should be "To Generate".');
                    //PCPL41-EWAY
                end;
            }
        }
    }
    trigger OnOpenPage();
    begin
        //PCPL41-EINV
        CLEAR(EINVGen);
        CLEAR(EINVCan);
        EINVDet.RESET;
        EINVDet.SETRANGE("Document No.", "No.");
        EINVDet.SETFILTER("EINV IRN No.", '<>%1', '');
        IF EINVDet.FINDFIRST THEN BEGIN
            EINVGen := FALSE;
            EINVCan := TRUE;
        END;

        EINVDet.RESET;
        EINVDet.SETRANGE("Document No.", "No.");
        EINVDet.SETFILTER("EINV IRN No.", '<>%1', '');
        IF NOT EINVDet.FINDFIRST THEN BEGIN
            EINVGen := TRUE;
            EINVCan := FALSE;
        END;
        //PCPL41-EINV
    end;

    var
        SalesInvHeader: Record 112;
        HasIncomingDocument: Boolean;
        ChangeExchangeRate: Page 511;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        CustLedgerEntry: Record 21;
        DocExchStatusStyle: Text;
        EINVDet: Record 50041;
        EINVGen: Boolean;
        EINVCan: Boolean;


    local procedure GenerateEInvoice();
    var
        EInvGT: DotNet EInvGT;
        token: Text;
        EInvGEI: DotNet EInvGEI;
        result: Text;
        resresult: Text;
        resresult1: Text;
        resresult2: Text;
        resresult3: Text;
        resresult4: Text;
        transactiondetails: Text;
        documentdetails: Text;
        sellerdetails: Text;
        buyerdetails: Text;
        dispatchdetails: Text;
        shipdetails: Text;
        exportdetails: Text;
        paymentdetails: Text;
        referencedetails: Text;
        valuedetails: Text;
        itemlist: Text;
        adddocdetails: Text;
        ewaybilldetails: Text;
        CompanyInformation: Record 79;
        Location: Record 14;
        State: Record State;
        Customer: Record 18;
        BuyState: Record State;
        ShiptoAddress: Record 222;
        ShipState: Record State;
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        SalesInvoiceLine: Record 113;
        CGSTAmt: Decimal;
        SGSTAmt: Decimal;
        IGSTAmt: Decimal;
        CESSGSTAmt: Decimal;
        CESSRate: Decimal;
        totaltaxableamt: Decimal;
        TotalCGSTAmt: Decimal;
        TotalSGSTAmt: Decimal;
        TotalIGSTAmt: Decimal;
        TotalCessGSTAmt: Decimal;
        totalcessnonadvolvalue: Decimal;
        totalinvoicevalue: Decimal;
        totalcessvalueofstate: Decimal;
        totaldiscount: Decimal;
        totalothercharge: Decimal;
        IsService: Text;
        GeneralLedgerSetup: Record 98;
        FileMgt: Codeunit 419;
        //TempBlob: Record 99008535; //PCPL/NSW/030522
        //<<PCPL/NSW/030522
        TempBlob1: Codeunit "Temp Blob";
        Outs: OutStream;
        IntS: InStream;
        //>>PCPL/NSW/030522
        ServerFileNameTxt: Text;
        EINVPos: Text;
        Document_Date: Text;
        TotalItemValue: Decimal;
        UOM: Text;
        EInvoiceDetail: Record 50041;
        LocPhoneNo: Text;
        CustPhoneNo: Text;
        GSTRate: Text;
        //PostedStrOrderLineDetails: Record "13798";
        UnitPrice: Decimal;
        TotVal: Decimal;
        AssVal: Decimal;
        customermaster: Record 18;
        cgstrate: Decimal;
        sgstrate: Decimal;
        igstrate: Decimal;
    begin
        //PCPL41-EINV
        customermaster.GET("Sell-to Customer No.");
        IF customermaster.SEZ THEN BEGIN
            transactiondetails := 'SEZWOP' + '!' + 'N' + '!' + '' + '!' + 'N';
        END ELSE
            transactiondetails := FORMAT("Nature of Supply") + '!' + 'N' + '!' + '' + '!' + 'N';

        Document_Date := FORMAT("Posting Date", 0, '<Day,2>/<Month,2>/<year4>');
        documentdetails := 'INV' + '!' + "No." + '!' + Document_Date;

        CompanyInformation.GET;
        Location.GET("Location Code");
        State.GET(Location."State Code");
        LocPhoneNo := DELCHR(Location."Phone No.", '=', '!|@|#|$|%|^|&|*|/|''|\|-| |(|)');
        sellerdetails := Location."GST Registration No." + '!' + CompanyInformation.Name + '!' + Location.Name + '!' + Location.Address + '!' + Location."Address 2" + '!' +
        Location.City + '!' + Location."Post Code" + '!' + State."State Code (GST Reg. No.)" + '!' + LocPhoneNo + '!' + Location."E-Mail";

        dispatchdetails := Location.Name + '!' + Location.Address + '!' + Location."Address 2" + '!' + "Location Code" + '!' + Location."Post Code" + '!' + State.Description;

        Customer.GET("Sell-to Customer No.");
        BuyState.GET(Customer."State Code");
        CustPhoneNo := DELCHR(Customer."Phone No.", '=', '!|@|#|$|%|^|&|*|/|''|\|-| |(|)');
        buyerdetails := Customer."GST Registration No." + '!' + Customer.Name + '!' + Customer."Name 2" + '!' + Customer.Address + '!' + Customer."Address 2" + '!' +
        Customer.City + '!' + Customer."Post Code" + '!' + BuyState."State Code (GST Reg. No.)" + '!' + BuyState.Description + '!' + CustPhoneNo + '!' +
        Customer."E-Mail";

        IF "Ship-to Code" <> '' THEN BEGIN
            ShiptoAddress.RESET;
            ShiptoAddress.SETRANGE(ShiptoAddress.Code, "Ship-to Code");
            ShiptoAddress.SETRANGE(ShiptoAddress."Customer No.", "Sell-to Customer No.");
            IF ShiptoAddress.FINDFIRST THEN BEGIN
                ShipState.GET(ShiptoAddress.State);
                shipdetails := ShiptoAddress."GST Registration No." + '!' + ShiptoAddress.Name + '!' + ShiptoAddress."Name 2" + '!' + ShiptoAddress.Address + '!' +
                ShiptoAddress."Address 2" + '!' + ShiptoAddress.City + '!' + ShiptoAddress."Post Code" + '!' + ShipState.Description;
            END ELSE
                shipdetails := Customer."GST Registration No." + '!' + Customer.Name + '!' + Customer."Name 2" + '!' + Customer.Address + '!' + Customer."Address 2" + '!' +
                Customer.City + '!' + Customer."Post Code" + '!' + BuyState.Description;
        END;

        exportdetails := '';
        paymentdetails := '';
        referencedetails := '';
        adddocdetails := '';
        ewaybilldetails := '';

        CLEAR(CGSTAmt);
        CLEAR(SGSTAmt);
        CLEAR(IGSTAmt);
        CLEAR(CESSGSTAmt);
        CLEAR(TotalCGSTAmt);
        CLEAR(TotalSGSTAmt);
        CLEAR(TotalIGSTAmt);
        CLEAR(TotalCessGSTAmt);
        CLEAR(totaltaxableamt);
        CLEAR(totalcessnonadvolvalue);
        CLEAR(totalinvoicevalue);
        CLEAR(totalcessvalueofstate);
        CLEAR(totaldiscount);
        CLEAR(totalothercharge);
        CLEAR(itemlist);
        CLEAR(UOM);

        SalesInvoiceLine.RESET;
        SalesInvoiceLine.SETCURRENTKEY("Document No.");
        SalesInvoiceLine.SETRANGE("Document No.", "No.");
        SalesInvoiceLine.SETFILTER(Type, '<>%1', SalesInvoiceLine.Type::" ");
        SalesInvoiceLine.SETFILTER("Unit of Measure Code", '<>%1', '');
        SalesInvoiceLine.SETFILTER(Quantity, '<>%1', 0);
        IF SalesInvoiceLine.FINDSET THEN
            REPEAT
                DetailedGSTLedgerEntry.RESET;
                DetailedGSTLedgerEntry.SETCURRENTKEY("Transaction Type", "Document Type", "Document No.", "Document Line No.");
                DetailedGSTLedgerEntry.SETRANGE("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Sales);
                DetailedGSTLedgerEntry.SETRANGE("Document No.", SalesInvoiceLine."Document No.");
                DetailedGSTLedgerEntry.SETRANGE("Document Line No.", SalesInvoiceLine."Line No.");
                IF DetailedGSTLedgerEntry.FINDSET THEN
                    REPEAT
                        IF DetailedGSTLedgerEntry."GST Component Code" = 'CGST' THEN BEGIN
                            CGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                            cgstrate := ABS(DetailedGSTLedgerEntry."GST %");
                        END ELSE
                            IF (DetailedGSTLedgerEntry."GST Component Code" = 'SGST') OR (DetailedGSTLedgerEntry."GST Component Code" = 'UTGST') THEN BEGIN
                                SGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                                sgstrate := ABS(DetailedGSTLedgerEntry."GST %");
                            END ELSE
                                IF DetailedGSTLedgerEntry."GST Component Code" = 'IGST' THEN BEGIN
                                    IGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                                    igstrate := ABS(DetailedGSTLedgerEntry."GST %");
                                END ELSE
                                    IF DetailedGSTLedgerEntry."GST Component Code" = 'CESS' THEN BEGIN
                                        CESSGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                                        CESSRate := DetailedGSTLedgerEntry."GST %";
                                    END;
                    UNTIL DetailedGSTLedgerEntry.NEXT = 0;

                CLEAR(GSTRate);
                IF (CGSTAmt <> 0) AND (SGSTAmt <> 0) THEN
                    GSTRate := FORMAT(cgstrate + sgstrate);
                IF IGSTAmt <> 0 THEN
                    GSTRate := FORMAT(igstrate);
                IF CESSGSTAmt <> 0 THEN
                    GSTRate := FORMAT(CESSRate);

                //S
                CLEAR(UnitPrice);
                CLEAR(TotVal);
                CLEAR(AssVal);
                CLEAR(TotalItemValue);

                //<<PCPL/NSW/MIG 14July22  Below Code Exist in BC18
                /*
                PostedStrOrderLineDetails.RESET;
                PostedStrOrderLineDetails.SETRANGE("Invoice No.", SalesInvoiceLine."Document No.");
                PostedStrOrderLineDetails.SETFILTER(Type, '%1', PostedStrOrderLineDetails.Type::Sale);
                PostedStrOrderLineDetails.SETRANGE("Line No.", SalesInvoiceLine."Line No.");
                PostedStrOrderLineDetails.SETRANGE("Item No.", SalesInvoiceLine."No.");
                IF PostedStrOrderLineDetails.FINDSET THEN
                    REPEAT
                        IF (PostedStrOrderLineDetails."Base Formula" = '1+2+3') OR (PostedStrOrderLineDetails."Base Formula" = '1+2') OR (PostedStrOrderLineDetails."Base Formula" = '1') THEN BEGIN
                            UnitPrice := SalesInvoiceLine."Charges To Customer" / SalesInvoiceLine.Quantity;
                            UnitPrice := ROUND(SalesInvoiceLine."Unit Price" + UnitPrice, 0.01, '>');
                            TotVal := SalesInvoiceLine.Quantity * UnitPrice;
                            AssVal := TotVal;
                            totaltaxableamt += AssVal;
                            TotalItemValue := AssVal + CGSTAmt + SGSTAmt + IGSTAmt + 0;//SalesInvoiceLine."TDS/TCS Amount";//PCPL/NSW/MIG 14July22
                            totalinvoicevalue += TotalItemValue;
                        END ELSE
                        */
                //>>PCPL/NSW/MIG
                IF (TotVal = 0) AND (AssVal = 0) THEN BEGIN
                    UnitPrice := ROUND(SalesInvoiceLine."Unit Price", 0.01, '>');
                    TotVal := ROUND(SalesInvoiceLine."Line Amount", 0.01, '>');
                    AssVal := TotVal;
                    totaltaxableamt += AssVal;
                    TotalItemValue := AssVal + CGSTAmt + SGSTAmt + IGSTAmt + 0;//SalesInvoiceLine."TDS/TCS Amount"; //PCPL/NSW/MIG 14July22
                    totalinvoicevalue += TotalItemValue;
                END;
                // UNTIL PostedStrOrderLineDetails.NEXT = 0;


                //E

                /*
                IF SalesInvoiceLine."GST Base Amount" = 0 THEN
                  totaltaxableamt += SalesInvoiceLine.Amount
                ELSE
                  totaltaxableamt += SalesInvoiceLine."GST Base Amount";
                */

                TotalCGSTAmt += CGSTAmt;
                TotalSGSTAmt += SGSTAmt;
                TotalIGSTAmt += IGSTAmt;
                TotalCessGSTAmt += CESSGSTAmt;

                //TotalItemValue := SalesInvoiceLine."Line Amount"+CGSTAmt+SGSTAmt+IGSTAmt+CESSGSTAmt+SalesInvoiceLine."TDS/TCS Amount"+SalesInvoiceLine."Charges To Customer";
                //totalinvoicevalue += SalesInvoiceLine."Line Amount"+CGSTAmt+SGSTAmt+IGSTAmt+CESSGSTAmt+SalesInvoiceLine."TDS/TCS Amount"+SalesInvoiceLine."Charges To Customer";
                //totaldiscount += SalesInvoiceLine."Line Discount Amount";
                //totalothercharge += SalesInvoiceLine."TDS/TCS Amount"+SalesInvoiceLine."Charges To Customer";
                //totalothercharge += SalesInvoiceLine."TDS/TCS Amount";

                IF SalesInvoiceLine."GST Group Type" = SalesInvoiceLine."GST Group Type"::Service THEN
                    IsService := 'Y'
                ELSE
                    IF SalesInvoiceLine."GST Group Type" = SalesInvoiceLine."GST Group Type"::Goods THEN
                        IsService := 'N';

                IF SalesInvoiceLine."Unit of Measure Code" = 'BL' THEN
                    UOM := 'OTH'
                ELSE
                    IF SalesInvoiceLine."Unit of Measure Code" = 'KG' THEN
                        UOM := 'KGS'
                    ELSE
                        IF SalesInvoiceLine."Unit of Measure Code" = 'MT' THEN
                            UOM := 'MTS'
                        ELSE
                            UOM := SalesInvoiceLine."Unit of Measure Code";

                /* //Old Code
                CLEAR(GSTRate);
                IF SalesInvoiceLine."GST %" = 0.1 THEN
                  GSTRate := FORMAT(SalesInvoiceLine."GST %")
                ELSE
                  GSTRate := FORMAT(ROUND(SalesInvoiceLine."GST %",1,'='));
                 */

                IF itemlist = '' THEN
                    /*
                    itemlist := FORMAT(SalesInvoiceLine."Line No.")+'!'+SalesInvoiceLine.Description+'!'+IsService+'!'+SalesInvoiceLine."HSN/SAC Code"+'!'+''+'!'+
                    FORMAT(SalesInvoiceLine.Quantity)+'!'+''+'!'+UOM+'!'+FORMAT(ROUND(SalesInvoiceLine."Unit Price",0.01,'>'))+'!'+
                    FORMAT(SalesInvoiceLine."Line Amount")+'!'+'0'+'!'+FORMAT(SalesInvoiceLine."Line Discount Amount")+'!'+FORMAT(SalesInvoiceLine."TDS/TCS Amount"+SalesInvoiceLine."Charges To Customer")+
                    '!'+FORMAT(SalesInvoiceLine."Tax Base Amount")+'!'+GSTRate+'!'+FORMAT(IGSTAmt)+'!'+FORMAT(CGSTAmt)+'!'+
                    FORMAT(SGSTAmt)+'!'+FORMAT(CESSRate)+'!'+FORMAT(CESSGSTAmt)+'!'+'0'+'!'+'0'+'!'+'0'+'!'+'0'+'!'+FORMAT(TotalItemValue)+
                    '!'+''+'!'+''+'!'+''+'!'+''+'!'+''+'!'+''+''+'!'+''
                  ELSE
                    itemlist := itemlist+';'+FORMAT(SalesInvoiceLine."Line No.")+'!'+SalesInvoiceLine.Description+'!'+IsService+'!'+SalesInvoiceLine."HSN/SAC Code"+
                    '!'+''+'!'+FORMAT(SalesInvoiceLine.Quantity)+'!'+''+'!'+UOM+'!'+
                    FORMAT(ROUND(SalesInvoiceLine."Unit Price",0.01,'>'))+'!'+FORMAT(SalesInvoiceLine."Line Amount")+'!'+'0'+'!'+
                    FORMAT(SalesInvoiceLine."Line Discount Amount")+'!'+FORMAT(SalesInvoiceLine."TDS/TCS Amount"+SalesInvoiceLine."Charges To Customer")+'!'+FORMAT(SalesInvoiceLine."Tax Base Amount")+'!'+
                    GSTRate+'!'+FORMAT(IGSTAmt)+'!'+FORMAT(CGSTAmt)+'!'+FORMAT(SGSTAmt)+'!'+FORMAT(CESSRate)+'!'+
                    FORMAT(CESSGSTAmt)+'!'+'0'+'!'+'0'+'!'+'0'+'!'+'0'+'!'+FORMAT(TotalItemValue)+'!'+''+'!'+''+'!'+''+'!'+''+'!'+''+'!'+''+
                    ''+'!'+''
                    */
            itemlist := FORMAT(SalesInvoiceLine."Line No.") + '!' + SalesInvoiceLine.Description + '!' + IsService + '!' + SalesInvoiceLine."HSN/SAC Code" + '!' + '' + '!' +
            FORMAT(SalesInvoiceLine.Quantity) + '!' + '' + '!' + UOM + '!' + FORMAT(UnitPrice) + '!' +
            FORMAT(TotVal) + '!' + '0' + '!' + FORMAT(SalesInvoiceLine."Line Discount Amount") + '!' + FORMAT(0/*SalesInvoiceLine."TDS/TCS Amount"*/) +
            '!' + FORMAT(AssVal) + '!' + GSTRate + '!' + FORMAT(IGSTAmt) + '!' + FORMAT(CGSTAmt) + '!' +
            FORMAT(SGSTAmt) + '!' + FORMAT(CESSRate) + '!' + FORMAT(CESSGSTAmt) + '!' + '0' + '!' + '0' + '!' + '0' + '!' + '0' + '!' + FORMAT(TotalItemValue) +
            '!' + '' + '!' + '' + '!' + '' + '!' + '' + '!' + '' + '!' + '' + '' + '!' + ''
                ELSE
                    itemlist := itemlist + ';' + FORMAT(SalesInvoiceLine."Line No.") + '!' + SalesInvoiceLine.Description + '!' + IsService + '!' + SalesInvoiceLine."HSN/SAC Code" +
                    '!' + '' + '!' + FORMAT(SalesInvoiceLine.Quantity) + '!' + '' + '!' + UOM + '!' +
                    FORMAT(UnitPrice) + '!' + FORMAT(TotVal) + '!' + '0' + '!' +
                    FORMAT(SalesInvoiceLine."Line Discount Amount") + '!' + FORMAT(0/*SalesInvoiceLine."TDS/TCS Amount"*/) + '!' + FORMAT(AssVal) + '!' +
                    GSTRate + '!' + FORMAT(IGSTAmt) + '!' + FORMAT(CGSTAmt) + '!' + FORMAT(SGSTAmt) + '!' + FORMAT(CESSRate) + '!' +
                    FORMAT(CESSGSTAmt) + '!' + '0' + '!' + '0' + '!' + '0' + '!' + '0' + '!' + FORMAT(TotalItemValue) + '!' + '' + '!' + '' + '!' + '' + '!' + '' + '!' + '' + '!' + '' +
                    '' + '!' + ''

UNTIL SalesInvoiceLine.NEXT = 0;

        valuedetails := FORMAT(totaltaxableamt) + '!' + FORMAT(TotalCGSTAmt) + '!' + FORMAT(TotalCGSTAmt) + '!' + FORMAT(TotalIGSTAmt) + '!' + FORMAT(TotalCessGSTAmt) + '!' +
        '0' + '!' + FORMAT(totalinvoicevalue) + '!' + '0' + '!' + '0' + '!' + '0' + '!' + FORMAT(totaldiscount) + '!' +
        FORMAT(totalothercharge);

        GeneralLedgerSetup.GET;
        EInvGT := EInvGT.TokenController;
        token := EInvGT.GetToken(GeneralLedgerSetup."EINV Base URL", GeneralLedgerSetup."EINV User Name", GeneralLedgerSetup."EINV Password",
        GeneralLedgerSetup."EINV Client ID", GeneralLedgerSetup."EINV Client Secret", GeneralLedgerSetup."EINV Grant Type");

        EInvGEI := EInvGEI.eInvoiceController;
        result := EInvGEI.GenerateEInvoice(GeneralLedgerSetup."EINV Base URL", token, Location."GST Registration No.", 'erp', transactiondetails,
        documentdetails, sellerdetails, buyerdetails, dispatchdetails, shipdetails, exportdetails, paymentdetails, referencedetails, adddocdetails,
        valuedetails, ewaybilldetails, itemlist, GeneralLedgerSetup."EINV Path", "No.");

        CLEAR(EINVPos);
        EINVPos := COPYSTR(result, 1, 8);

        IF EINVPos = 'SUCCESS;' THEN BEGIN
            resresult := CONVERTSTR(result, ';', ',');
            resresult1 := SELECTSTR(1, resresult);
            resresult2 := SELECTSTR(2, resresult);
            resresult3 := SELECTSTR(3, resresult);
            resresult4 := SELECTSTR(4, resresult);

            IF resresult1 = 'SUCCESS' THEN BEGIN
                IF NOT EInvoiceDetail.GET("No.") THEN BEGIN
                    EInvoiceDetail.INIT;
                    EInvoiceDetail."Document No." := "No.";
                    EInvoiceDetail."EINV IRN No." := resresult2;
                    EInvoiceDetail."URL For PDF" := resresult4;

                    SLEEP(3000);
                    resresult3 := FileMgt.DownloadTempFile(resresult3);

                    SLEEP(5000);
                    //ServerFileNameTxt := FileMgt.UploadFileSilent(resresult3);
                    //FileMgt.BLOBImportFromServerFile(TempBlob, ServerFileNameTxt);
                    FileMgt.BLOBImportFromServerFile(TempBlob1, resresult3); //PCPL/MIG/NSW BC18 Customized code add coz above code not work in BC18
                    SLEEP(5000);
                    //<<PCPL/NSW/EINV 050522 New Code Added as compatible for BC 19
                    TempBlob1.CreateInStream(IntS);
                    EInvoiceDetail."EINV QR Code".CreateOutStream(Outs);
                    CopyStream(Outs, IntS);
                    //EInvoiceDetail."EINV QR Code" := TempBlob.Blob;
                    //>>PCPL/NSW/EINV 050522 New Code Added as compatible for BC 19
                    EInvoiceDetail.INSERT;

                    //FILE.ERASE(ServerFileNameTxt); //PCPL/NSW/14July22

                    MESSAGE('E-Invoice has been generated.');
                END;
            END;
        END ELSE
            ERROR(result);
        //PCPL41-EINV

    end;

    local procedure CancelEInvoice();
    var
        GeneralLedgerSetup: Record 98;
        Location: Record 14;
        EInvGT: DotNet EInvGT;//"'PCPL.eInvoice.Integration, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'.PCPL.eInvoice.Integration.TokenController";
        token: Text;
        EInvGEI: DotNet EInvGEI;//"'PCPL.eInvoice.Integration, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'.PCPL.eInvoice.Integration.eInvoiceController";
        CancelPos: Text;
        result: Text;
        resresult: Text;
        resresult1: Text;
        resresult2: Text;
        EInvoiceDetail: Record 50041;
    begin
        //PCPL41-EINV
        IF EInvoiceDetail.GET("No.") THEN BEGIN
            GeneralLedgerSetup.GET;
            EInvGT := EInvGT.TokenController;
            token := EInvGT.GetToken(GeneralLedgerSetup."EINV Base URL", GeneralLedgerSetup."EINV User Name", GeneralLedgerSetup."EINV Password",
            GeneralLedgerSetup."EINV Client ID", GeneralLedgerSetup."EINV Client Secret", GeneralLedgerSetup."EINV Grant Type");

            Location.GET("Location Code");
            EInvGEI := EInvGEI.eInvoiceController;
            result := EInvGEI.CancelEInvoice(GeneralLedgerSetup."EINV Base URL", token, Location."GST Registration No.", EInvoiceDetail."EINV IRN No.", EInvoiceDetail."Cancel Remark", '1',
            "No.", GeneralLedgerSetup."EINV Path");

            CLEAR(CancelPos);
            CancelPos := COPYSTR(result, 1, 2);

            IF CancelPos = 'Y;' THEN BEGIN
                resresult := CONVERTSTR(result, ';', ',');
                resresult1 := SELECTSTR(1, resresult);
                resresult2 := SELECTSTR(2, resresult);

                IF resresult1 = 'Y' THEN BEGIN
                    EInvoiceDetail."Cancel IRN No." := resresult2;
                    EInvoiceDetail."EINV IRN No." := '';
                    CLEAR(EInvoiceDetail."URL For PDF");
                    CLEAR(EInvoiceDetail."EINV QR Code");
                    EInvoiceDetail.MODIFY;
                    MESSAGE('E-Invoice has been cancelled');
                END;
            END ELSE
                ERROR(result);
        END;
        //PCPL41-EINV
    end;

    procedure Ewaybill_returnV(SalesInvHdr: Record 112);
    var
        Headerdata: Text;
        Linedata: Text;
        Cust: Record 18;
        SalesInvLine: Record 113;
        Location_: Record 14;
        State_: Record State;
        StateCust: Record State;
        ShiptoCode: Record 222;
        ComInfo: Record 79;
        HSNSAN: Record "HSN/SAC";
        ShipQty: Decimal;
        cnt: Integer;
        Item_: Record 27;
        DetailedGSTLedgerEntry: Record 18001;
        CGSTAmt: Decimal;
        SGSTAmt: Integer;
        IGSTAmt: Decimal;
        CESSGSTAmt: Integer;
        CgstRate: Decimal;
        SgstRate: Integer;
        IgstRate: Decimal;
        CESSgstRate: Integer;
        TotalCGSTAmt: Decimal;
        TotalSGSTAmt: Integer;
        TotalIGSTAmt: Decimal;
        TotalCESSGSTAmt: Integer;
        Document_Date: Text;
        UOMeasure: Text;
        FromGST: Text;
        ToGST: Text;
        TotalTaxableAmt: Decimal;
        LineTaxableAmt: Decimal;
        LineInvoiceAmt: Decimal;
        Supply: Text;
        Subsupply: Text;
        SubSupplydescr: Text;
        PathText: Text;
        UomValue: Text;
        DocumentType: Text;
        EWayBillDetail: Record 50042;
        GeneralLedgerSetup: Record 98;
        TotaltaxableAmt1: Text;
        Ewaybill: DotNet EwaybillController;//"'PCPL.eWaybill.Integration, Version=1.0.0.1, Culture=neutral, PublicKeyToken=null'.PCPL.eWaybill.Integration.eWaybillController";
        token: Text;
        result: Text;
        resresult: Text;
        resresult1: Text;
        resresult2: Text;
        //<<PCPL/NSW/EINV 052522
        SalesInvLineNewEway: Record 113;
        TaxRecordIDEWAY: RecordId;
        TCSAMTLinewiseEWAY: Decimal;
        GSTBaseAmtLineWiseEWAY: Decimal;
        ComponentJobjectEWAY: JsonObject;
        //EWayBillDetail: Record 50008;
        SalesInvHeader: Record 112;
        TotalAmttoCust: Decimal;
    //>>PCPL/NSW/EINV 052522
    begin
        //PCPL41-EWAY
        ComInfo.GET;
        IF Cust.GET(SalesInvHdr."Sell-to Customer No.") THEN;
        IF Location_.GET(SalesInvHdr."Location Code") THEN;
        IF State_.GET(Location_."State Code") THEN;
        IF ShiptoCode.GET(SalesInvHdr."Sell-to Customer No.", SalesInvHdr."Ship-to Code") THEN;
        IF StateCust.GET(Cust."State Code") THEN;

        //SalesInvHdr.CALCFIELDS("Amount to Customer"); //PCPL/NSW/MIG 14July22

        TotalIGSTAmt := 0;
        TotalCGSTAmt := 0;
        cnt := 0;
        Linedata := '[';
        TotalTaxableAmt := 0;
        CGSTAmt := 0;
        IGSTAmt := 0;
        ShipQty := 0;
        CgstRate := 0;
        IgstRate := 0;
        LineTaxableAmt := 0;
        LineInvoiceAmt := 0;
        //<<PCPL/NSW/EINV 052522
        Clear(GSTBaseAmtLineWiseEWAY);
        Clear(TCSAMTLinewiseEWAY);
        Clear(TaxRecordIDEWAY);
        Clear(TotalAmttoCust);
        //<<PCPL/NSW/EINV 052522
        SalesInvLine.RESET;
        SalesInvLine.SETCURRENTKEY("Document No.", "Line No.");
        SalesInvLine.SETRANGE("Document No.", SalesInvHdr."No.");
        SalesInvLine.SETFILTER("No.", '<>%1', '413007');
        IF SalesInvLine.FINDSET THEN
            REPEAT
                DetailedGSTLedgerEntry.RESET;
                DetailedGSTLedgerEntry.SETCURRENTKEY("Transaction Type", "Document Type", "Document No.", "Document Line No.");
                DetailedGSTLedgerEntry.SETRANGE("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Sales);
                DetailedGSTLedgerEntry.SETRANGE("Document No.", SalesInvLine."Document No.");
                DetailedGSTLedgerEntry.SETRANGE("Document Line No.", SalesInvLine."Line No.");
                IF DetailedGSTLedgerEntry.FINDSET THEN
                    REPEAT
                        IF DetailedGSTLedgerEntry."GST Component Code" = 'CGST' THEN BEGIN
                            CGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                            CgstRate := DetailedGSTLedgerEntry."GST %";
                            Supply := 'Outward';
                            Subsupply := 'Supply';
                            SubSupplydescr := '';
                        END ELSE
                            IF DetailedGSTLedgerEntry."GST Component Code" = 'SGST' THEN BEGIN
                                SGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                                SgstRate := DetailedGSTLedgerEntry."GST %";
                                Supply := 'Outward';
                                Subsupply := 'Supply';
                                SubSupplydescr := '';
                            END ELSE
                                IF DetailedGSTLedgerEntry."GST Component Code" = 'IGST' THEN BEGIN
                                    IGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                                    IgstRate := DetailedGSTLedgerEntry."GST %";
                                    Supply := 'Outward';
                                    Subsupply := 'Supply';
                                END ELSE
                                    IF DetailedGSTLedgerEntry."GST Component Code" = 'CESS' THEN BEGIN
                                        CESSGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                                        CESSgstRate := DetailedGSTLedgerEntry."GST %";
                                        Supply := 'Outward';
                                        Subsupply := 'Supply';
                                    END;
                    UNTIL DetailedGSTLedgerEntry.NEXT = 0;

                IF SalesInvLine."Unit of Measure Code" = 'PAIR' THEN
                    UomValue := 'PRS'
                ELSE
                    UomValue := 'PCS';

                TotalCGSTAmt += CGSTAmt;
                TotalSGSTAmt += SGSTAmt;
                TotalIGSTAmt += IGSTAmt;
                TotalCESSGSTAmt += CESSGSTAmt;

                //<<PCPL/NSW/EINV 052522
                if SalesInvLineNewEway.Get(SalesInvLine."Document No.", SalesInvLine."Line No.") then
                    TaxRecordIDEWAY := SalesInvLine.RecordId();
                TCSAMTLinewiseEWAY := GetTcsAmtLineWiseEway(TaxRecordIDEWAY, ComponentJobjectEWAY);
                GSTBaseAmtLineWiseEWAY := GetGSTBaseAmtLineWiseEWAY(TaxRecordIDEWAY, ComponentJobjectEWAY);

                //>>PCPL/NSW/EINV 052522

                IF GSTBaseAmtLineWiseEWAY = 0 THEN BEGIN
                    TotalTaxableAmt += SalesInvLine.Amount;
                    DocumentType := 'Delivery Challan';
                    Supply := 'Outward';
                    Subsupply := 'Others';
                    SubSupplydescr := 'Others';
                END ELSE BEGIN
                    TotalTaxableAmt += GSTBaseAmtLineWiseEWAY;//SalesInvLine."GST Base Amount"; //PCPL/NSW/MIG 07July22
                    DocumentType := 'Tax Invoice';
                    Supply := 'Outward';
                    Subsupply := 'Supply';
                END;
                LineTaxableAmt += GSTBaseAmtLineWiseEWAY;//SalesInvLine."GST Base Amount"; //PCPL/NSW/MIG  07July22
                LineInvoiceAmt += SalesInvLine.Amount + GSTBaseAmtLineWiseEWAY; //SalesInvLine."Amount To Customer"; //PCPL/NSW/MIG  07July22 Amt to Cust field not Exist in BC18
                ShipQty += SalesInvLine.Quantity;
                IF Item_.GET(SalesInvLine."No.") THEN;


            UNTIL SalesInvLine.NEXT = 0;
        TotalAmttoCust := LineInvoiceAmt;//PCPL/NSW/MIG 14July22 New code add coz Amttocust not exist in BC18

        IF TotalTaxableAmt > 1000 THEN
            TotaltaxableAmt1 := DELCHR(FORMAT(TotalTaxableAmt), '=', ',');

        IF ShipQty <> 0 THEN BEGIN
            cnt += 1;
            IF cnt = 1 THEN
                Linedata += '{"product_name":"' + Item_.Description + '","product_description":"' + Item_.Description + '","hsn_code":"' +
                SalesInvLine."HSN/SAC Code" + '","quantity":"' + FORMAT(ShipQty) + '","unit_of_product":"' + UomValue + '","cgst_rate":"' + FORMAT(CgstRate) +
                '","sgst_rate":"' + FORMAT(SgstRate) + '","igst_rate":"' + FORMAT(IgstRate) + '","cess_rate":"' + FORMAT(CESSgstRate) + '","cessNonAdvol":"' + '0' +
                '","taxable_amount":"' + FORMAT(TotaltaxableAmt1) + '"}'
            ELSE
                Linedata += ',{"product_name":"' + Item_.Description + '","product_description":"' + Item_.Description + '","hsn_code":"' +
                SalesInvLine."HSN/SAC Code" + '","quantity":"' + FORMAT(ShipQty) + '","unit_of_product":"' + UomValue + '","cgst_rate":"' + FORMAT(CgstRate) +
                '","sgst_rate":"' + FORMAT(SgstRate) + '","igst_rate":"' + FORMAT(IgstRate) + '","cess_rate":"' + FORMAT(CESSgstRate) + '","cessNonAdvol":"' + '0' +
                  '","taxable_amount":"' + FORMAT(TotaltaxableAmt1) + '"}';
        END;

        Linedata := Linedata + ']';

        GeneralLedgerSetup.GET;
        Ewaybill := Ewaybill.eWaybillController;
        token := Ewaybill.GetToken(GeneralLedgerSetup."EINV Base URL", GeneralLedgerSetup."EINV User Name", GeneralLedgerSetup."EINV Password",
        GeneralLedgerSetup."EINV Client ID", GeneralLedgerSetup."EINV Client Secret", GeneralLedgerSetup."EINV Grant Type", GeneralLedgerSetup."EINV Path");

        IF EWayBillDetail.GET(SalesInvHdr."No.") THEN BEGIN
            WITH SalesInvHdr DO BEGIN
                Document_Date := FORMAT("Document Date", 0, '<Day,2>/<Month,2>/<year4>');
                Headerdata := '{"access_token":"' + token + '","userGstin":"' + Location_."GST Registration No." + '","supply_type":"' + Supply + '","sub_supply_type":"' + Subsupply +
                '","sub_supply_description":"' + SubSupplydescr + '","document_type":"' + DocumentType + '","document_number":"' + SalesInvHdr."No." +
                '","document_date":"' + Document_Date + '","gstin_of_consignor":"' + Location_."GST Registration No." + '","legal_name_of_consignor":"' + Location_.Name +
                '","address1_of_consignor":"' + Location_.Address + '","address2_of_consignor":"' + Location_."Address 2" + '","place_of_consignor":"' +
                Location_.City + '","pincode_of_consignor":"' + Location_."Post Code" + '","state_of_consignor":"' + State_.Description +
                '","actual_from_state_name":"' + State_.Description + '","gstin_of_consignee":"' + Cust."GST Registration No." + '","legal_name_of_consignee":"' + Cust.Name +
                '","address1_of_consignee":"' + Cust.Address + '","address2_of_consignee":"' + Cust."Address 2" +
                '","place_of_consignee":"' + Cust.City + '","pincode_of_consignee":"' + Cust."Post Code" + '","state_of_supply":"' + StateCust.Description +
                '","actual_to_state_name":"' + StateCust.Description + '","transaction_type":"' + SalesInvHdr."Transaction Type" + '","other_value":"' + '' +
                '","total_invoice_value":"' + FORMAT(TotalAmttoCust/*"Amount to Customer"*/) + '","taxable_amount":"' + FORMAT(TotaltaxableAmt1) + '","cgst_amount":"' +
                FORMAT(TotalCGSTAmt) + '","sgst_amount":"' + FORMAT(TotalSGSTAmt) + '","igst_amount":"' + FORMAT(TotalIGSTAmt) + '","cess_amount":"' +
                FORMAT(TotalCESSGSTAmt) + '","cess_nonadvol_value":"' + '0' + '","transporter_id":"' + EWayBillDetail."Transporter Id" + '","transporter_name":"' +
                EWayBillDetail."Transporter Name" + '","transporter_document_number":"' + '' + '","transporter_document_date":"' + '' + '","transportation_mode":"' +
                EWayBillDetail."Transportation Mode" + '","transportation_distance":"' + FORMAT(EWayBillDetail."Transport Distance") + '","vehicle_number":"' +
                SalesInvHdr."Vehicle No." + '","vehicle_type":"' + 'Regular' + '","generate_status":"' + '1' + '","data_source":"' + 'erp' + '","user_ref":"' + '' +
                '","location_code":"' + Location_.Code + '","eway_bill_status":"' + FORMAT(SalesInvHdr."E-Way Bill Generate") + '","auto_print":"' + 'Y' + '","email":"' +
                Location_."E-Mail" + '"}';
            END;
        END;

        result := Ewaybill.GenerateEwaybill(GeneralLedgerSetup."EINV Base URL", token, Headerdata, Linedata, GeneralLedgerSetup."EINV Path");

        resresult := CONVERTSTR(result, ';', ',');
        resresult1 := SELECTSTR(1, resresult);
        resresult2 := SELECTSTR(2, resresult);

        IF 12 = STRLEN(resresult1) THEN BEGIN
            IF EWayBillDetail.GET(SalesInvHdr."No.") THEN BEGIN
                EWayBillDetail."Eway Bill No." := resresult1;
                EWayBillDetail."URL For PDF" := resresult2;
                EWayBillDetail."Ewaybill Error" := '';
                EWayBillDetail.MODIFY;

                SalesInvHdr."E-Way Bill Generate" := SalesInvHdr."E-Way Bill Generate"::Generated;
                SalesInvHdr.MODIFY;
                MESSAGE(resresult1);
            END;
        END ELSE BEGIN
            EWayBillDetail."Ewaybill Error" := result;
            EWayBillDetail.MODIFY;
            COMMIT;
            ERROR(result);
        END;
        //PCPL41-EWAY
    end;


    procedure Ewaybill_returnV_Test(SalesInvHdr: Record 112);
    var
        Headerdata: Text;
        Linedata: Text;
        Cust: Record 18;
        SalesInvLine: Record 113;
        Location_: Record 14;
        State_: Record State;
        StateCust: Record State;
        ShiptoCode: Record 222;
        ComInfo: Record 79;
        HSNSAN: Record "HSN/SAC";
        ShipQty: Decimal;
        cnt: Integer;
        Item_: Record 27;
        DetailedGSTLedgerEntry: Record 18001;
        CGSTAmt: Decimal;
        SGSTAmt: Integer;
        IGSTAmt: Decimal;
        CESSGSTAmt: Integer;
        CgstRate: Decimal;
        SgstRate: Integer;
        IgstRate: Decimal;
        CESSgstRate: Integer;
        TotalCGSTAmt: Decimal;
        TotalSGSTAmt: Integer;
        TotalIGSTAmt: Decimal;
        TotalCESSGSTAmt: Integer;
        Document_Date: Text;
        UOMeasure: Text;
        FromGST: Text;
        ToGST: Text;
        TotalTaxableAmt: Decimal;
        LineTaxableAmt: Decimal;
        LineInvoiceAmt: Decimal;
        Supply: Text;
        Subsupply: Text;
        SubSupplydescr: Text;
        PathText: Text;
        UomValue: Text;
        DocumentType: Text;
        EWayBillDetail: Record 50042;
        GeneralLedgerSetup: Record 98;
        TotaltaxableAmt1: Text;
        Ewaybill: DotNet EwaybillController;//"'PCPL.eWaybill.Integration, Version=1.0.0.1, Culture=neutral, PublicKeyToken=null'.PCPL.eWaybill.Integration.eWaybillController";
        token: Text;
        result: Text;
        resresult: Text;
        resresult1: Text;
        resresult2: Text;
        //<<PCPL/NSW/EINV 052522
        SalesInvLineNewEway: Record 113;
        TaxRecordIDEWAY: RecordId;
        TCSAMTLinewiseEWAY: Decimal;
        GSTBaseAmtLineWiseEWAY: Decimal;
        ComponentJobjectEWAY: JsonObject;
        //EWayBillDetail: Record 50008;
        SalesInvHeader: Record 112;
        TotalAmttoCust: Decimal;
    //>>PCPL/NSW/EINV 052522
    begin
        //PCPL41-EWAY
        ComInfo.GET;
        IF Cust.GET(SalesInvHdr."Sell-to Customer No.") THEN;
        IF Location_.GET(SalesInvHdr."Location Code") THEN;
        IF State_.GET(Location_."State Code") THEN;
        IF ShiptoCode.GET(SalesInvHdr."Sell-to Customer No.", SalesInvHdr."Ship-to Code") THEN;
        IF StateCust.GET(Cust."State Code") THEN;

        // SalesInvHdr.CALCFIELDS("Amount to Customer"); //PCPL/NSW/MIG  14July22

        TotalIGSTAmt := 0;
        TotalCGSTAmt := 0;
        cnt := 0;
        Linedata := '[';
        TotalTaxableAmt := 0;
        CGSTAmt := 0;
        IGSTAmt := 0;
        ShipQty := 0;
        CgstRate := 0;
        IgstRate := 0;
        LineTaxableAmt := 0;
        LineInvoiceAmt := 0;
        //<<PCPL/NSW/EINV 052522
        Clear(GSTBaseAmtLineWiseEWAY);
        Clear(TCSAMTLinewiseEWAY);
        Clear(TaxRecordIDEWAY);
        Clear(TotalAmttoCust);
        //<<PCPL/NSW/EINV 052522
        SalesInvLine.RESET;
        SalesInvLine.SETCURRENTKEY("Document No.", "Line No.");
        SalesInvLine.SETRANGE("Document No.", SalesInvHdr."No.");
        SalesInvLine.SETFILTER("No.", '<>%1', '413007');
        IF SalesInvLine.FINDSET THEN
            REPEAT
                DetailedGSTLedgerEntry.RESET;
                DetailedGSTLedgerEntry.SETCURRENTKEY("Transaction Type", "Document Type", "Document No.", "Document Line No.");
                DetailedGSTLedgerEntry.SETRANGE("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Sales);
                DetailedGSTLedgerEntry.SETRANGE("Document No.", SalesInvLine."Document No.");
                DetailedGSTLedgerEntry.SETRANGE("Document Line No.", SalesInvLine."Line No.");
                IF DetailedGSTLedgerEntry.FINDSET THEN
                    REPEAT
                        IF DetailedGSTLedgerEntry."GST Component Code" = 'CGST' THEN BEGIN
                            CGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                            CgstRate := DetailedGSTLedgerEntry."GST %";
                            Supply := 'Outward';
                            Subsupply := 'Supply';
                            SubSupplydescr := '';
                        END ELSE
                            IF DetailedGSTLedgerEntry."GST Component Code" = 'SGST' THEN BEGIN
                                SGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                                SgstRate := DetailedGSTLedgerEntry."GST %";
                                Supply := 'Outward';
                                Subsupply := 'Supply';
                                SubSupplydescr := '';
                            END ELSE
                                IF DetailedGSTLedgerEntry."GST Component Code" = 'IGST' THEN BEGIN
                                    IGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                                    IgstRate := DetailedGSTLedgerEntry."GST %";
                                    Supply := 'Outward';
                                    Subsupply := 'Supply';
                                END ELSE
                                    IF DetailedGSTLedgerEntry."GST Component Code" = 'CESS' THEN BEGIN
                                        CESSGSTAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                                        CESSgstRate := DetailedGSTLedgerEntry."GST %";
                                        Supply := 'Outward';
                                        Subsupply := 'Supply';
                                    END;
                    UNTIL DetailedGSTLedgerEntry.NEXT = 0;

                IF SalesInvLine."Unit of Measure Code" = 'PAIR' THEN
                    UomValue := 'PRS'
                ELSE
                    UomValue := 'PCS';

                TotalCGSTAmt += CGSTAmt;
                TotalSGSTAmt += SGSTAmt;
                TotalIGSTAmt += IGSTAmt;
                TotalCESSGSTAmt += CESSGSTAmt;

                //<<PCPL/NSW/EINV 052522
                if SalesInvLineNewEway.Get(SalesInvLine."Document No.", SalesInvLine."Line No.") then
                    TaxRecordIDEWAY := SalesInvLine.RecordId();
                TCSAMTLinewiseEWAY := GetTcsAmtLineWiseEway(TaxRecordIDEWAY, ComponentJobjectEWAY);
                GSTBaseAmtLineWiseEWAY := GetGSTBaseAmtLineWiseEWAY(TaxRecordIDEWAY, ComponentJobjectEWAY);

                //>>PCPL/NSW/EINV 052522

                IF GSTBaseAmtLineWiseEWAY = 0 THEN BEGIN
                    TotalTaxableAmt += SalesInvLine.Amount;
                    DocumentType := 'Delivery Challan';
                    Supply := 'Outward';
                    Subsupply := 'Others';
                    SubSupplydescr := 'Others';
                END ELSE BEGIN
                    TotalTaxableAmt += GSTBaseAmtLineWiseEWAY;//SalesInvLine."GST Base Amount";
                    DocumentType := 'Tax Invoice';
                    Supply := 'Outward';
                    Subsupply := 'Supply';
                END;
                LineTaxableAmt += GSTBaseAmtLineWiseEWAY;//SalesInvLine."GST Base Amount";
                LineInvoiceAmt += SalesInvLine.Amount + GSTBaseAmtLineWiseEWAY;//SalesInvLine."Amount To Customer";
                ShipQty += SalesInvLine.Quantity;
                IF Item_.GET(SalesInvLine."No.") THEN;

            UNTIL SalesInvLine.NEXT = 0;
        TotalAmttoCust := LineInvoiceAmt;

        IF TotalTaxableAmt > 1000 THEN
            TotaltaxableAmt1 := DELCHR(FORMAT(TotalTaxableAmt), '=', ',');

        IF ShipQty <> 0 THEN BEGIN
            cnt += 1;
            IF cnt = 1 THEN
                Linedata += '{"product_name":"' + Item_.Description + '","product_description":"' + Item_.Description + '","hsn_code":"' +
                SalesInvLine."HSN/SAC Code" + '","quantity":"' + FORMAT(ShipQty) + '","unit_of_product":"' + UomValue + '","cgst_rate":"' + FORMAT(CgstRate) +
                '","sgst_rate":"' + FORMAT(SgstRate) + '","igst_rate":"' + FORMAT(IgstRate) + '","cess_rate":"' + FORMAT(CESSgstRate) + '","cessNonAdvol":"' + '0' +
                '","taxable_amount":"' + FORMAT(TotaltaxableAmt1) + '"}'
            ELSE
                Linedata += ',{"product_name":"' + Item_.Description + '","product_description":"' + Item_.Description + '","hsn_code":"' +
                SalesInvLine."HSN/SAC Code" + '","quantity":"' + FORMAT(ShipQty) + '","unit_of_product":"' + UomValue + '","cgst_rate":"' + FORMAT(CgstRate) +
                '","sgst_rate":"' + FORMAT(SgstRate) + '","igst_rate":"' + FORMAT(IgstRate) + '","cess_rate":"' + FORMAT(CESSgstRate) + '","cessNonAdvol":"' + '0' +
                  '","taxable_amount":"' + FORMAT(TotaltaxableAmt1) + '"}';
        END;

        Linedata := Linedata + ']';

        GeneralLedgerSetup.GET;
        Ewaybill := Ewaybill.eWaybillController;
        token := Ewaybill.GetToken(GeneralLedgerSetup."EINV Base URL", GeneralLedgerSetup."EINV User Name", GeneralLedgerSetup."EINV Password",
        GeneralLedgerSetup."EINV Client ID", GeneralLedgerSetup."EINV Client Secret", GeneralLedgerSetup."EINV Grant Type", GeneralLedgerSetup."EINV Path");

        IF EWayBillDetail.GET(SalesInvHdr."No.") THEN BEGIN
            WITH SalesInvHdr DO BEGIN
                Document_Date := FORMAT("Document Date", 0, '<Day,2>/<Month,2>/<year4>');
                /* Headerdata :='{"access_token":"'+token+'","userGstin":"'+Location_."GST Registration No."+'","supply_type":"'+Supply+'","sub_supply_type":"'+Subsupply+
                 '","sub_supply_description":"'+SubSupplydescr+'","document_type":"'+DocumentType+'","document_number":"'+SalesInvHdr."No."+
                 '","document_date":"'+Document_Date+'","gstin_of_consignor":"'+Location_."GST Registration No."+'","legal_name_of_consignor":"'+Location_.Name+
                 '","address1_of_consignor":"'+Location_.Address+'","address2_of_consignor":"'+Location_."Address 2"+'","place_of_consignor":"'+
                 Location_.City+'","pincode_of_consignor":"'+Location_."Post Code"+'","state_of_consignor":"'+State_.Description+
                 '","actual_from_state_name":"'+State_.Description+'","gstin_of_consignee":"'+Cust."GST Registration No."+'","legal_name_of_consignee":"'+Cust.Name+
                 '","address1_of_consignee":"'+Cust.Address+'","address2_of_consignee":"'+Cust."Address 2"+
                 '","place_of_consignee":"'+Cust.City+'","pincode_of_consignee":"'+Cust."Post Code"+'","state_of_supply":"'+StateCust.Description+
                 '","actual_to_state_name":"'+StateCust.Description+'","transaction_type":"'+SalesInvHdr."Transaction Type"+'","other_value":"'+''+
                 '","total_invoice_value":"'+FORMAT("Amount to Customer")+'","taxable_amount":"'+FORMAT(TotaltaxableAmt1)+'","cgst_amount":"'+
                 FORMAT(TotalCGSTAmt)+'","sgst_amount":"'+FORMAT(TotalSGSTAmt) + '","igst_amount":"'+FORMAT(TotalIGSTAmt)+'","cess_amount":"'+
                 FORMAT(TotalCESSGSTAmt)+'","cess_nonadvol_value":"'+'0'+'","transporter_id":"'+EWayBillDetail."Transporter Id"+'","transporter_name":"'+
                 EWayBillDetail."Transporter Name"+'","transporter_document_number":"'+''+'","transporter_document_date":"'+''+'","transportation_mode":"'+
                 EWayBillDetail."Transportation Mode"+'","transportation_distance":"'+FORMAT(EWayBillDetail."Transport Distance")+'","vehicle_number":"'+
                 SalesInvHdr."Vehicle No." +'","vehicle_type":"'+'Regular'+'","generate_status":"'+'1'+'","data_source":"'+'erp'+'","user_ref":"'+''+
                 '","location_code":"'+Location_.Code+'","eway_bill_status":"'+FORMAT(SalesInvHdr."E-Way Bill Generate")+'","auto_print":"'+'Y'+'","email":"'+
                 Location_."E-Mail"+'"}';
                 */
                Headerdata := '{"access_token":"' + token + '","userGstin":"' + '05AAABC0181E1ZE' + '","supply_type":"' + Supply + '","sub_supply_type":"' + Subsupply +
                '","sub_supply_description":"' + SubSupplydescr + '","document_type":"' + DocumentType + '","document_number":"' + SalesInvHdr."No." +
                '","document_date":"' + Document_Date + '","gstin_of_consignor":"' + '05AAABC0181E1ZE' + '","legal_name_of_consignor":"' + Location_.Name +
                '","address1_of_consignor":"' + Location_.Address + '","address2_of_consignor":"' + Location_."Address 2" + '","place_of_consignor":"' +
                Location_.City + '","pincode_of_consignor":"' + Location_."Post Code" + '","state_of_consignor":"' + State_.Description +
                '","actual_from_state_name":"' + State_.Description + '","gstin_of_consignee":"' + '05AAABB0639G1Z8' + '","legal_name_of_consignee":"' + Cust.Name +
                '","address1_of_consignee":"' + Cust.Address + '","address2_of_consignee":"' + Cust."Address 2" +
                '","place_of_consignee":"' + Cust.City + '","pincode_of_consignee":"' + Cust."Post Code" + '","state_of_supply":"' + StateCust.Description +
                '","actual_to_state_name":"' + StateCust.Description + '","transaction_type":"' + SalesInvHdr."Transaction Type" + '","other_value":"' + '' +
                '","total_invoice_value":"' + FORMAT(TotalAmttoCust/*"Amount to Customer"*/) + '","taxable_amount":"' + FORMAT(TotaltaxableAmt1) + '","cgst_amount":"' +
                FORMAT(TotalCGSTAmt) + '","sgst_amount":"' + FORMAT(TotalSGSTAmt) + '","igst_amount":"' + FORMAT(TotalIGSTAmt) + '","cess_amount":"' +
                FORMAT(TotalCESSGSTAmt) + '","cess_nonadvol_value":"' + '0' + '","transporter_id":"' + '05AAABC0181E1ZE' + '","transporter_name":"' +
                EWayBillDetail."Transporter Name" + '","transporter_document_number":"' + "LR/RR No." + '","transporter_document_date":"' + FORMAT("LR/RR Date") + '","transportation_mode":"' +
                EWayBillDetail."Transportation Mode" + '","transportation_distance":"' + FORMAT(EWayBillDetail."Transport Distance") + '","vehicle_number":"' +
                SalesInvHdr."Vehicle No." + '","vehicle_type":"' + 'Regular' + '","generate_status":"' + '1' + '","data_source":"' + 'erp' + '","user_ref":"' + '' +
                '","location_code":"' + Location_.Code + '","eway_bill_status":"' + FORMAT(SalesInvHdr."E-Way Bill Generate") + '","auto_print":"' + 'Y' + '","email":"' +
                Location_."E-Mail" + '"}';
            END;
        END;

        result := Ewaybill.GenerateEwaybill(GeneralLedgerSetup."EINV Base URL", token, Headerdata, Linedata, GeneralLedgerSetup."EINV Path");

        resresult := CONVERTSTR(result, ';', ',');
        resresult1 := SELECTSTR(1, resresult);
        resresult2 := SELECTSTR(2, resresult);

        IF 12 = STRLEN(resresult1) THEN BEGIN
            IF EWayBillDetail.GET(SalesInvHdr."No.") THEN BEGIN
                EWayBillDetail."Eway Bill No." := resresult1;
                EWayBillDetail."URL For PDF" := resresult2;
                EWayBillDetail."Ewaybill Error" := '';
                EWayBillDetail.MODIFY;

                SalesInvHdr."E-Way Bill Generate" := SalesInvHdr."E-Way Bill Generate"::Generated;
                SalesInvHdr.MODIFY;
                MESSAGE(resresult1);
            END;
        END ELSE BEGIN
            EWayBillDetail."Ewaybill Error" := result;
            EWayBillDetail.MODIFY;
            COMMIT;
            ERROR(result);
        END;
        //PCPL41-EWAY

    end;

    //PCPL/NSW/EINV 050522
    local procedure GetTcsAmtLineWiseEway(TaxRecordID: RecordId; var JObject: JsonObject): Decimal
    var
        TaxTransactionValue: Record "Tax Transaction Value";
        TaxTypeObjHelper: Codeunit "Tax Type Object Helper";
        ComponentAmtTCS: Decimal;
        JArray: JsonArray;
        ComponentJObject: JsonObject;
    begin
        if not GuiAllowed then
            exit;

        TaxTransactionValue.SetFilter("Tax Record ID", '%1', TaxRecordID);
        TaxTransactionValue.SetFilter("Value Type", '%1', TaxTransactionValue."Value Type"::Component);
        TaxTransactionValue.SetRange("Visible on Interface", true);
        TaxTransactionValue.SetRange("Tax Type", 'TCS');
        //if TaxTransactionValue.FindSet() then
        if TaxTransactionValue.FindFirst() then
            //repeat
            begin
            Clear(ComponentJObject);
            //ComponentJObject.Add('Component', TaxTransactionValue.GetAttributeColumName());
            //ComponentJObject.Add('Percent', ScriptDatatypeMgmt.ConvertXmlToLocalFormat(format(TaxTransactionValue.Percent, 0, 9), "Symbol Data Type"::NUMBER));
            ComponentAmtTCS := TaxTypeObjHelper.GetComponentAmountFrmTransValue(TaxTransactionValue);
            //ComponentJObject.Add('Amount', ScriptDatatypeMgmt.ConvertXmlToLocalFormat(format(ComponentAmt, 0, 9), "Symbol Data Type"::NUMBER));
            JArray.Add(ComponentJObject);
        end;
        //        TCSAMTLinewise := ComponentAmt;
        //until TaxTransactionValue.Next() = 0;
        exit(ComponentAmtTCS)

    end;

    Local procedure GetGSTBaseAmtLineWiseEWAY(TaxRecordID: RecordId; var JObject: JsonObject): Decimal
    var
        TaxTransactionValue: Record "Tax Transaction Value";
        TaxTypeObjHelper: Codeunit "Tax Type Object Helper";
        ComponentAmtGSTVBase: Decimal;
        JArray: JsonArray;
        ComponentJObject: JsonObject;
    begin
        if not GuiAllowed then
            exit;

        TaxTransactionValue.SetFilter("Tax Record ID", '%1', TaxRecordID);
        TaxTransactionValue.SetFilter("Value Type", '%1', TaxTransactionValue."Value Type"::Component);
        TaxTransactionValue.SetRange("Visible on Interface", true);
        TaxTransactionValue.SetRange("Tax Type", 'GST');
        TaxTransactionValue.SetRange("Value ID", 10);
        //if TaxTransactionValue.FindSet() then
        if TaxTransactionValue.FindFirst() then
            //repeat
            begin
            Clear(ComponentJObject);
            //ComponentJObject.Add('Component', TaxTransactionValue.GetAttributeColumName());
            //ComponentJObject.Add('Percent', ScriptDatatypeMgmt.ConvertXmlToLocalFormat(format(TaxTransactionValue.Percent, 0, 9), "Symbol Data Type"::NUMBER));
            ComponentAmtGSTVBase := TaxTypeObjHelper.GetComponentAmountFrmTransValue(TaxTransactionValue);
            //ComponentJObject.Add('Amount', ScriptDatatypeMgmt.ConvertXmlToLocalFormat(format(ComponentAmt, 0, 9), "Symbol Data Type"::NUMBER));
            JArray.Add(ComponentJObject);
        end;
        exit(ComponentAmtGSTVBase)

    end;
    //PCPL/NSW/EINV 050522






}