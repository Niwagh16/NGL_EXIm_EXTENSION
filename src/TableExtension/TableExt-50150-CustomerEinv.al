tableextension 50150 Customer_Einv_ext extends Customer
{
    fields
    {
        field(50104; SEZ; Boolean)
        {
            Description = 'PCPL-EINV';
        }
    }

    var
        myInt: Integer;
}