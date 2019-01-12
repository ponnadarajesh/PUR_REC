tableextension 50062 StdVendorPurchCodeRecurring extends 175
{
    fields
    {
        // Add changes to table fields here
        field(50061; "Recurring Period"; DateFormula)
        {
            Caption = 'Recurring Period';
            Description = 'Rec1.0';
        }
        field(50062; "Next Invoice Date"; Date)
        {
            Caption = 'Next Invoice Date';
            Description = 'Rec1.0';
        }
        field(50063; "Add Purch Line for Bill Period"; Boolean)
        {
            Caption = 'Add Purch Line for Bill Period';
            Description = 'Rec1.0';
        }
        field(50064; "Shortcut Dimension 1 Code"; code[20])
        {
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE ("Global Dimension No." = CONST (1));
            CaptionClass = '1,2,1';
            Description = 'Rec1.0';
        }
        field(50065; "Shortcut Dimension 2 Code"; code[20])
        {
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE ("Global Dimension No." = CONST (2));
            CaptionClass = '1,2,2';
            Description = 'Rec1.0';
        }
        field(50066; "Valid From Date"; Date)
        {
            Caption = 'Valid From Date';
            Description = 'Rec1.0';
        }
        field(50067; "Valid To date"; Date)
        {
            Caption = 'Valid To date';
            Description = 'Rec1.0';
        }
        field(50068; "Payment Method Code"; code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
            Description = 'Rec1.0';
        }
        field(50069; "Payment Term"; Code[10])
        {
            Caption = 'Payment Term';
            TableRelation = "Payment Terms";
            Description = 'Rec1.0';
        }
        field(50070; Blocked; Boolean)
        {
            Caption = 'Blocked';
            Description = 'Rec1.0';
        }
    }
}