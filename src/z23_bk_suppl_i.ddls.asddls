@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IFV : Booking Supplement Details'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z23_BK_SUPPL_I
  as select from z23_bk_suppl
  association     to parent Z23_BOOKING_I as _Booking on $projection.BookingUuid = _Booking.BookingUuid
  association [1] to Z23_TRAVEL_I         as _Travel  on $projection.travelUuid = _Travel.TravelUuid
{
  key booksuppl_uuid        as BooksupplUuid,
      root_uuid             as travelUuid,
      parent_uuid           as BookingUuid,
      booking_supplement_id as BookingSupplementId,
      supplement_id         as SupplementId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      currency_code         as CurrencyCode,
      local_last_changed_at as LocalLastChangedAt,
      _Booking, // Make association public
      _Travel
}
