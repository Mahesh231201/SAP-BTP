@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PJV : Booking Supplement Details'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity Z23_BK_SUPPL_C
  as projection on Z23_BK_SUPPL_I
{
  key BooksupplUuid,
      travelUuid,
      BookingUuid,
      BookingSupplementId,
      SupplementId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Price,
      CurrencyCode,
      LocalLastChangedAt,
      /* Associations */
      _Booking : redirected to parent Z23_BOOKING_C,
      _Travel  : redirected to Z23_TRAVEL_C
}
