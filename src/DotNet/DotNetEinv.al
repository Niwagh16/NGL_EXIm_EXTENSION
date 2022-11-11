dotnet
{
    assembly(PCPL.eInvoice.Integration)
    {
        type(PCPL.eInvoice.Integration.TokenController; EInvGT)
        {

        }
        type(PCPL.eInvoice.Integration.eInvoiceController; EInvGEI)
        {

        }


    }
    Assembly(PCPL.eWaybill.Integration)
    {
        type(PCPL.eWaybill.Integration.eWaybillController; EwaybillController)
        {

        }
    }
}
