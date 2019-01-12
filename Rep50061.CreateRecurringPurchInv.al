report 50061 "Create Recurring Purch Inv.AL"
{
    // version CW4.09

    Caption = 'Create Recurring Purch Inv.';
    ProcessingOnly = true;
    UsageCategory = Administration;
    UseRequestPage = false;

    dataset
    {
        dataitem("Standard Vendor Purchase Code"; "Standard Vendor Purchase Code")
        {
            RequestFilterFields = "Vendor No.", "Code";

            trigger OnAfterGetRecord()
            begin
                Vendor.RESET;
                IF Vendor.GET("Vendor No.") THEN BEGIN
                    IF Vendor.Blocked <> Vendor.Blocked::" " THEN
                        CurrReport.SKIP;
                END;
                IF ("Next Invoice Date" <> 0D) AND ("Next Invoice Date" <= WORKDATE) THEN BEGIN
                    Counter += 1;
                    CreatePurchInvoice(OrderDate, PostingDate);
                END
            end;

            trigger OnPreDataItem()
            begin
                SETFILTER("Valid From Date", '%1|<=%2', 0D, OrderDate);
                SETFILTER("Valid To date", '%1|>=%2', 0D, OrderDate);
                SETFILTER("Next Invoice Date", '%1|<=%2', 0D, WORKDATE);
                SETRANGE(Blocked, FALSE);

                //TotalCount := COUNT;
                //Window.OPEN(ProgressMsg);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(OrderDate; OrderDate)
                {
                    Caption = 'Order Date';
                }
                field(PostingDate; PostingDate)
                {
                    Caption = 'Posting Date';
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        //Window.CLOSE;
        //MESSAGE(NoOfInvoicesMsg,TotalCount);
    end;

    trigger OnPreReport()
    begin
        //IF (OrderDate = 0D) OR (PostingDate = 0D) THEN
        //ERROR(MissingDatesErr);
        OrderDate := WORKDATE;
        PostingDate := WORKDATE;
    end;

    var
        Window: Dialog;
        PostingDate: Date;
        OrderDate: Date;
        MissingDatesErr: Label 'You must enter both a posting date and an order date.';
        TotalCount: Integer;
        Counter: Integer;
        ProgressMsg: Label 'Creating Invoices #1##################';
        NoOfInvoicesMsg: Label '%1 invoices were created.';
        Vendor: Record Vendor;
        InvFromDate: Date;
        InvTodate: Date;
        ReleasePurchDoc: Codeunit "Release Purchase Document";

    procedure CreatePurchInvoice(OrderDate: Date; PostingDate: Date)
    var
        PurchHeader: Record "Purchase Header";
        StdPurchCode: Record "Standard Purchase Code";
    begin
        "Standard Vendor Purchase Code".TESTFIELD(Blocked, FALSE);
        PurchHeader.INIT;
        PurchHeader."No." := '';
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        //PurchHeader."Recurring Invoice" := TRUE;                                                           //HBSRP
        PurchHeader.INSERT(TRUE);
        //PurchHeader.CallFromRecurringPurch(TRUE);
        PurchHeader.VALIDATE("Buy-from Vendor No.", "Standard Vendor Purchase Code"."Vendor No.");
        PurchHeader.VALIDATE("Order Date", OrderDate);
        PurchHeader.VALIDATE("Posting Date", PostingDate);
        PurchHeader.VALIDATE("Document Date", OrderDate);
        IF "Standard Vendor Purchase Code"."Shortcut Dimension 1 Code" <> '' THEN
            PurchHeader.VALIDATE("Shortcut Dimension 1 Code", "Standard Vendor Purchase Code"."Shortcut Dimension 1 Code");
        IF "Standard Vendor Purchase Code"."Shortcut Dimension 2 Code" <> '' THEN
            PurchHeader.VALIDATE("Shortcut Dimension 2 Code", "Standard Vendor Purchase Code"."Shortcut Dimension 2 Code");
        IF "Standard Vendor Purchase Code"."Payment Method Code" <> '' THEN
            PurchHeader.VALIDATE("Payment Method Code", "Standard Vendor Purchase Code"."Payment Method Code");
        IF "Standard Vendor Purchase Code"."Payment Term" <> '' THEN
            PurchHeader.VALIDATE("Payment Terms Code", "Standard Vendor Purchase Code"."Payment Term");
        StdPurchCode.GET("Standard Vendor Purchase Code".Code);
        PurchHeader."Reason Code" := StdPurchCode."Reason Code";
        PurchHeader."Vendor Invoice No." := PurchHeader."No." + FORMAT(WORKDATE, 0, '<Month,2><Year,2>');
        PurchHeader.MODIFY;
        ApplyStdCodesToPurchaseLines(PurchHeader, "Standard Vendor Purchase Code");
        IF FORMAT("Standard Vendor Purchase Code"."Recurring Period") <> '' THEN BEGIN
            IF "Standard Vendor Purchase Code"."Next Invoice Date" <> 0D THEN
                "Standard Vendor Purchase Code"."Next Invoice Date" := CALCDATE("Standard Vendor Purchase Code"."Recurring Period", "Standard Vendor Purchase Code"."Next Invoice Date")
            ELSE
                "Standard Vendor Purchase Code"."Next Invoice Date" := CALCDATE("Standard Vendor Purchase Code"."Recurring Period", TODAY);
            "Standard Vendor Purchase Code".MODIFY;
        END;
        //ReleasePurchDoc.RUN(PurchHeader);
    end;

    procedure ApplyStdCodesToPurchaseLines(PurchHeader: Record "Purchase Header"; StdVendPurchCode: Record "Standard Vendor Purchase Code")
    var
        Currency: Record Currency;
        PurchLine: Record "Purchase Line";
        StdPurchLine: Record "Standard Purchase Line";
        StdPurchCode: Record "Standard Purchase Code";
        Factor: Integer;
    begin
        IF PurchHeader."Currency Code" = '' THEN
            Currency.InitRoundingPrecision
        ELSE
            Currency.GET(PurchHeader."Currency Code");

        StdVendPurchCode.TESTFIELD(Code);
        StdVendPurchCode.TESTFIELD("Vendor No.", PurchHeader."Buy-from Vendor No.");
        StdPurchCode.GET(StdVendPurchCode.Code);
        StdPurchCode.TESTFIELD("Currency Code", PurchHeader."Currency Code");
        StdPurchLine.SETRANGE("Standard Purchase Code", StdVendPurchCode.Code);
        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine.SETRANGE("Document Type", PurchHeader."Document Type");
        PurchLine.SETRANGE("Document No.", PurchHeader."No.");
        IF PurchHeader."Prices Including VAT" THEN
            Factor := 1
        ELSE
            Factor := 0;

        //ReSRP 2018-03-08 Start:
        IF StdVendPurchCode."Next Invoice Date" <> 0D THEN BEGIN
            InvFromDate := StdVendPurchCode."Next Invoice Date";
            InvTodate := CALCDATE('-1D', CALCDATE(StdVendPurchCode."Recurring Period", StdVendPurchCode."Next Invoice Date"));
        END;
        //ReSRP 2018-03-08 End:

        PurchLine.LOCKTABLE;
        StdPurchLine.LOCKTABLE;
        IF StdPurchLine.FIND('-') THEN
            REPEAT
                PurchLine.INIT;
                PurchLine."Line No." := 0;
                PurchLine.VALIDATE(Type, StdPurchLine.Type);
                IF StdPurchLine.Type = StdPurchLine.Type::" " THEN BEGIN
                    PurchLine.VALIDATE("No.", StdPurchLine."No.");
                    PurchLine.Description := StdPurchLine.Description
                END ELSE
                    IF NOT StdPurchLine.EmptyLine THEN BEGIN
                        StdPurchLine.TESTFIELD("No.");
                        PurchLine.VALIDATE("No.", StdPurchLine."No.");
                        IF StdPurchLine."Variant Code" <> '' THEN
                            PurchLine.VALIDATE("Variant Code", StdPurchLine."Variant Code");
                        PurchLine.VALIDATE(Quantity, StdPurchLine.Quantity);
                        IF StdPurchLine."Unit of Measure Code" <> '' THEN
                            PurchLine.VALIDATE("Unit of Measure Code", StdPurchLine."Unit of Measure Code");
                        PurchLine.Description := StdPurchLine.Description;
                        IF (StdPurchLine.Type = StdPurchLine.Type::"G/L Account") OR
                           (StdPurchLine.Type = StdPurchLine.Type::"Charge (Item)")
                        THEN
                            PurchLine.VALIDATE(
                              "Direct Unit Cost",
                              ROUND(StdPurchLine."Amount Excl. VAT" *
                                (PurchLine."VAT %" / 100 * Factor + 1), Currency."Unit-Amount Rounding Precision"));
                    END;

                PurchLine."Shortcut Dimension 1 Code" := StdPurchLine."Shortcut Dimension 1 Code";
                PurchLine."Shortcut Dimension 2 Code" := StdPurchLine."Shortcut Dimension 2 Code";

                CombineDimensions(PurchLine, StdPurchLine);

                IF StdPurchLine.InsertLine THEN BEGIN
                    PurchLine."Line No." := GetNextLineNo(PurchLine);
                    PurchLine.INSERT(TRUE);
                    InsertExtendedText(PurchLine);
                END;
            UNTIL StdPurchLine.NEXT = 0;

        //insert Billing Text
        //ReSRP 2018-03-08 Start:
        IF StdVendPurchCode."Add Purch Line for Bill Period" THEN BEGIN
            PurchLine.INIT;
            PurchLine."Line No." := GetNextLineNo(PurchLine);
            PurchLine.Description := 'Invoice for Period: ' + FORMAT(InvFromDate) + ' to ' + FORMAT(InvTodate);
            PurchLine.INSERT(TRUE);
        END;
        //ReSRP 2018-03-08 End:
    end;

    local procedure CombineDimensions(var PurchaseLine: Record "Purchase Line"; StdPurchaseLine: Record "Standard Purchase Line")
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        DimensionSetIDArr[1] := PurchaseLine."Dimension Set ID";
        DimensionSetIDArr[2] := StdPurchaseLine."Dimension Set ID";

        PurchaseLine."Dimension Set ID" :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, PurchaseLine."Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 2 Code");
    end;

    local procedure InsertExtendedText(PurchLine: Record "Purchase Line")
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        IF TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, FALSE) THEN
            TransferExtendedText.InsertPurchExtText(PurchLine);
    end;

    local procedure GetNextLineNo(PurchLine: Record "Purchase Line"): Integer
    begin
        PurchLine.SETRANGE("Document Type", PurchLine."Document Type");
        PurchLine.SETRANGE("Document No.", PurchLine."Document No.");
        IF PurchLine.FINDLAST THEN
            EXIT(PurchLine."Line No." + 10000);

        EXIT(10000);
    end;
}

