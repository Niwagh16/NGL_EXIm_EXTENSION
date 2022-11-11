tableextension 50152 General_Led_Setup_ext extends "General Ledger Setup"
{
    // version NAVW19.00.00.48466,NAVIN9.00.00.48466,TFS180484\\pcpl0024_FILE GEN,PCPL41-EINV|EWAY

    fields
    {
        field(50008; "EINV Base URL"; Text[50])
        {
            Description = 'PCPL41-EINV';
        }
        field(50009; "EINV User Name"; Text[40])
        {
            Description = 'PCPL41-EINV';
        }
        field(50010; "EINV Password"; Text[20])
        {
            Description = 'PCPL41-EINV';
        }
        field(50011; "EINV Client ID"; Text[30])
        {
            Description = 'PCPL41-EINV';
        }
        field(50012; "EINV Client Secret"; Text[30])
        {
            Description = 'PCPL41-EINV';
        }
        field(50013; "EINV Grant Type"; Text[15])
        {
            Description = 'PCPL41-EINV';
        }
        field(50014; "EINV Path"; Text[50])
        {
            Description = 'PCPL41-EINV';
        }
    }
}

