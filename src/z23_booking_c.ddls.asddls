@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PJV : Booking Details'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity Z23_BOOKING_C
  as projection on Z23_BOOKING_I
{
  key BookingUuid,
      travelUuid,
      BookingId,
      BookingDate,
      CustomerId,
      CarrierId,
      ConnectionId,
      FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      CurrencyCode,
      BookingStatus,
      LocalLastChangedAt,
      /* Associations */
      _BookingSupplement : redirected to composition child z23_bk_suppl_c,
      _Travel            : redirected to parent Z23_TRAVEL_C
}
