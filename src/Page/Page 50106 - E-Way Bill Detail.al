page 50106 "E-Way Bill Detail"
{
    // version PCPL41-EWAY

    PageType = ListPart;
    SourceTable = 50042;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Eway Bill No.";"Eway Bill No.")
                {
                   ApplicationArea = all;
                }
                field("Ewaybill Error";"Ewaybill Error")
                {
                    ApplicationArea = all;
                }
                field("Transporter Id";"Transporter Id")
                {
                    ApplicationArea = all;
                }
                field("Transporter Name";"Transporter Name")
                {
                    ApplicationArea = all;
                }
                field("Transport Distance";"Transport Distance")
                {
                    ApplicationArea = all;
                }
                field("Transportation Mode";"Transportation Mode")
                {
                    ApplicationArea = all;
                }
                field("URL For PDF";"URL For PDF")
                {
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
    }
}

