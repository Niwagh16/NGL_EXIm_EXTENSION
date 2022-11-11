page 50105 "E-Invoice Detail"
{
    // version PCPL41-EINV

    PageType = CardPart;
    SourceTable = 50041;

    layout
    {
        area(content)
        {
            field("EINV IRN No."; "EINV IRN No.")
            {
                ApplicationArea = all;
                Editable = false;
            }
            field("EINV QR Code"; "EINV QR Code")
            {
                Editable = false;
                ApplicationArea = all;
            }
            field("Cancel Remark"; "Cancel Remark")
            {
                ApplicationArea = all;
                Editable = false;
            }
            field("Cancel IRN No."; "Cancel IRN No.")
            {
                ApplicationArea = all;
                Editable = false;
            }
            field("URL For PDF"; "URL For PDF")
            {
                ApplicationArea = all;
                Editable = false;
            }
        }
    }

    actions
    {
    }
}

