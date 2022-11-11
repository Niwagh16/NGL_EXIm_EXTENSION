tableextension 50151 Sales_inv_Header extends "Sales Invoice Header"
{
    // version NAVW19.00.00.48067,NAVIN9.00.00.48067,GITLEXIM,TFS180484,//PCPL-25-IGSTAppl,PCPL41-EWAY

    fields
    {

        field(50044; "E-Way Bill Generate"; Option)
        {
            Description = 'PCPL41-EWAY';
            OptionCaptionML = ENU = ',To Generate,Generated',
                              ENN = ',To Generate,Generated';
            OptionMembers = ,"To Generate",Generated;
        }
    }

}

