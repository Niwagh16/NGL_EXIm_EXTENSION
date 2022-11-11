table 50041 "E-Invoice Detail"
{
    // version PCPL41-EINV


    fields
    {
        field(1;"Document No.";Code[16])
        {
            Editable = false;
        }
        field(2;"EINV IRN No.";Text[64])
        {
            Editable = false;
        }
        field(3;"EINV QR Code";BLOB)
        {
            SubType = Bitmap;
        }
        field(4;"Cancel Remark";Text[100])
        {
        }
        field(5;"Cancel IRN No.";Text[64])
        {
            Editable = false;
        }
        field(6;"URL For PDF";Text[100])
        {
            Editable = false;
            ExtendedDatatype = URL;
        }
    }

    keys
    {
        key(Key1;"Document No.")
        {
        }
    }

    fieldgroups
    {
    }
}

