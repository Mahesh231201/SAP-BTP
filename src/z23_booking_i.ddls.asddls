@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IFV : Booking Details'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z23_BOOKING_I
  as select from z23_booking
  association to parent Z23_TRAVEL_I   as _Travel on $projection.travelUuid = _Travel.TravelUuid
  composition [0..*] of Z23_BK_SUPPL_I as _BookingSupplement
{
  key booking_uuid          as BookingUuid,
      parent_uuid           as travelUuid,
      booking_id            as BookingId,
      booking_date          as BookingDate,
      customer_id           as CustomerId,
      carrier_id            as CarrierId,
      connection_id         as ConnectionId,
      flight_date           as FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price          as FlightPrice,
      currency_code         as CurrencyCode,
      booking_status        as BookingStatus,
      local_last_changed_at as LocalLastChangedAt,
      _Travel, // Make association public
      _BookingSupplement
}
