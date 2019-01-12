tableextension 50061 StdPurchCodeRecurring extends 173
{
    fields
    {
        // Add changes to table fields here
        field(50061; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            Description = 'Rec1.0';
            TableRelation = "Reason Code".Code;
        }

    }
}