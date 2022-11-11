table 50042 "E-Way Bill Detail"
{
    // version PCPL41-EWAY

    DrillDownPageID = 132;
    LookupPageID = 132;
    Permissions = TableData 112 = r;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(2; "Eway Bill No."; Text[12])
        {
            Editable = false;
        }
        field(3; "Ewaybill Error"; Text[250])
        {
            Editable = false;
        }
        field(4; "Transporter Id"; Code[20])
        {
        }
        field(5; "Transporter Name"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Transport Distance"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Transportation Mode"; Text[10])
        {
            DataClassification = ToBeClassified;
        }
        field(8; "URL For PDF"; Text[100])
        {
            Editable = false;
            ExtendedDatatype = URL;
        }
    }

    keys
    {
        key(Key1; "Document No.")
        {
        }
    }

    fieldgroups
    {
    }
}

