CLASS lsc_z23_travel_i DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_z23_travel_i IMPLEMENTATION.

  METHOD save_modified.

    DATA : travel_log        TYPE STANDARD TABLE OF z23_travel_log,
           travel_log_create TYPE STANDARD TABLE OF z23_travel_log,
           travel_log_update TYPE STANDARD TABLE OF z23_travel_log.

    IF create-travel IS NOT INITIAL.

      travel_log = CORRESPONDING #( create-travel ).

      LOOP AT travel_log ASSIGNING FIELD-SYMBOL(<lfs_travel_log>).

        <lfs_travel_log>-changing_operation = 'CREATE'.
        GET TIME STAMP FIELD <lfs_travel_log>-created_at.
        TRY.
            <lfs_travel_log>-change_id = cl_system_uuid=>create_uuid_x16_static(  ).
          CATCH cx_uuid_error.
        ENDTRY.

        IF create-travel[ 1 ]-%control-BookingFee = cl_abap_behv=>flag_changed.
          <lfs_travel_log>-changed_field_name = 'Booking Fee'.
          <lfs_travel_log>-changed_value = create-travel[ 1 ]-BookingFee.
        ENDIF.


        IF create-travel[ 1 ]-%control-AgencyId = cl_abap_behv=>flag_changed.
          <lfs_travel_log>-changed_field_name = 'Agency Id'.
          <lfs_travel_log>-changed_value = create-travel[ 1 ]-AgencyId.
        ENDIF.

      ENDLOOP.

      MODIFY  z23_travel_log FROM TABLE @travel_log_create.

    ENDIF.

    IF update-travel IS NOT INITIAL.

      travel_log = CORRESPONDING #( update-travel ).
      LOOP AT travel_log ASSIGNING FIELD-SYMBOL(<lfs_travel_update>).

        <lfs_travel_update>-changing_operation = 'UPDATE'.
        GET TIME STAMP FIELD <lfs_travel_UPDATE>-created_at.
        TRY.
            <lfs_travel_update>-change_id = cl_system_uuid=>create_uuid_x16_static(  ).
          CATCH cx_uuid_error.
        ENDTRY.

        IF update-travel[ 1 ]-%control-BookingFee = cl_abap_behv=>flag_changed.
          <lfs_travel_update>-changed_field_name = 'Booking Fee'.
          <lfs_travel_update>-changed_value = create-travel[ 1 ]-BookingFee.
        ENDIF.


        IF update-travel[ 1 ]-%control-AgencyId = cl_abap_behv=>flag_changed.
          <lfs_travel_update>-changed_field_name = 'Agency Id'.
          <lfs_travel_update>-changed_value = create-travel[ 1 ]-AgencyId.
        ENDIF.

      ENDLOOP.

      MODIFY  z23_travel_log FROM TABLE @travel_log_update.

    ENDIF.

    IF delete-travel IS NOT INITIAL.



    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_bookingsupplement DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS SetBookingSupplId FOR DETERMINE ON SAVE
      IMPORTING keys FOR BookingSupplement~SetBookingSupplId.

    METHODS CalculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR BookingSupplement~CalculateTotalPrice.

ENDCLASS.

CLASS lhc_bookingsupplement IMPLEMENTATION.

  METHOD SetBookingSupplId.

    DATA : max_bookingSUPPLid  TYPE /dmo/booking_supplement_id,
           bookingsuppliment   TYPE STRUCTURE FOR READ RESULT z23_bk_suppl_i,
           BOOKINGSUPPL_uPDATE TYPE TABLE FOR UPDATE z23_travel_i\\BookingSupplement.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY BookingSupplement BY \_Booking
    FIELDS ( BookingUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(bookings).

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Booking BY \_BookingSupplement
    FIELDS ( BookingSupplementId )
    WITH CORRESPONDING #( bookings )
    LINK DATA(bookingsuppl_links)
    RESULT DATA(bookingSUPPLIMENTS).

    LOOP AT bookings INTO DATA(booking).

      "   Initialize the BookingId Number
      max_bookingSUPPLid = '00'.

      LOOP AT bookingSUPPL_links INTO DATA(bookingSUPPL_link) USING KEY id WHERE source-%tky = booking-%tky.

        bookingsuppliment = bookingsuppliments[ KEY id
                            %tky = bookingSUPPL_link-target-%tky ].

        IF booking-BookingId >  max_bookingSUPPLid .
          max_bookingSUPPLid  = booking-BookingId.
        ENDIF.

      ENDLOOP.

      LOOP AT bookingSUPPL_links INTO bookingSUPPL_link USING KEY id WHERE source-%tky = booking-%tky.

        bookingsuppliment = bookingsuppliments[ KEY id
                            %tky = bookingSUPPL_link-target-%tky ].

        IF booking-BookingId IS INITIAL.
          max_bookingSUPPLid  += 1.
          APPEND VALUE #( %tky = bookingsuppliment-%tky
                           bookingsupplementid =  max_bookingSUPPLid
                        ) TO bookingsuppl_update .

        ENDIF.

      ENDLOOP.

    ENDLOOP.


    MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY BookingSupplement
    UPDATE FIELDS ( BookingSupplementId )
    WITH bookingsuppl_update.


  ENDMETHOD.

  METHOD CalculateTotalPrice.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY BookingSupplement BY  \_Travel
    FIELDS ( TravelUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(Travels).

    MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    EXECUTE recalctotalprice
    FROM CORRESPONDING #( travels ).

  ENDMETHOD.

ENDCLASS.




CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS SetBookingId FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~SetBookingId.

    METHODS CalculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~CalculateTotalPrice.

    METHODS SetBookingDate FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~SetBookingDate.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD SetBookingId.

    DATA : max_bookingid   TYPE /dmo/booking_id,
           Booking         TYPE STRUCTURE FOR READ RESULT z23_booking_i,
           Bookings_update TYPE TABLE FOR UPDATE  z23_travel_i\\Booking.

*    We Are Reading Booking Entity get the traveluuid field for the current Booking instance and store that in the Travels Table

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Booking BY \_Travel
    FIELDS ( TravelUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

*    Now read all the Bookings related to Travel Which we got from top travels Table.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel BY \_Booking
    FIELDS ( BookingId )
    WITH CORRESPONDING #( Travels )
    LINK DATA(Booking_links)
    RESULT DATA(bookings).

    LOOP AT travels INTO DATA(Travel).

      "   Initialize the BookingId Number
      max_bookingid = '0000'.

      LOOP AT booking_links INTO DATA(booking_link) USING KEY id WHERE source-%tky = travel-%tky.

        booking = bookings[ KEY id
                            %tky = booking_link-target-%tky ].

        IF booking-BookingId > max_bookingid.
          max_bookingid = booking-BookingId.
        ENDIF.

      ENDLOOP.

      LOOP AT booking_links INTO booking_link USING KEY id WHERE source-%tky = travel-%tky.

        booking = bookings[ KEY id
                            %tky = booking_link-target-%tky ].

        IF booking-BookingId IS INITIAL.
          max_bookingid += 1.
          APPEND VALUE #( %tky = booking-%tky
                           bookingid = max_bookingid
                        ) TO bookings_update.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

*    Use Modify EML to update the bookings entity with the new bookingid number which is max_bookingid

    MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Booking
    UPDATE FIELDS ( BookingId )
    WITH bookings_update.

  ENDMETHOD.

  METHOD CalculateTotalPrice.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Booking BY  \_Travel
    FIELDS ( TravelUuid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(Travels).

    MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    EXECUTE recalctotalprice
    FROM CORRESPONDING #( travels ).


  ENDMETHOD.

  METHOD SetBookingDate.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
         ENTITY Booking
         FIELDS ( BookingDate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(Bookings).

    DELETE bookings WHERE BookingDate IS NOT INITIAL.

    CHECK bookings IS NOT INITIAL.

    LOOP AT bookings ASSIGNING FIELD-SYMBOL(<booking>).

      <booking>-BookingDate = cl_abap_context_info=>get_system_date( ).

    ENDLOOP.

    MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
           ENTITY Booking
           UPDATE FIELDS ( BookingDate )
           WITH CORRESPONDING #( Bookings ).

  ENDMETHOD.

ENDCLASS.




CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS setTravelId FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~setTravelId.

    METHODS setOverallStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~setOverallStatus.

    METHODS AcceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~AcceptTravel RESULT result.

    METHODS RejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~RejectTravel RESULT result.

    METHODS DeductDiscount FOR MODIFY
      IMPORTING keys FOR ACTION Travel~DeductDiscount RESULT result.

    METHODS GetDefaultsForDeductDiscount FOR READ
      IMPORTING keys FOR FUNCTION Travel~GetDefaultsForDeductDiscount RESULT result.

    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION Travel~recalctotalprice.

    METHODS CalculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~CalculateTotalPrice.

    METHODS ValidateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~ValidateCustomer.

    METHODS ValidateAgency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~ValidateAgency.

    METHODS ValidateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~ValidateDates.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

***    DETERMINATIONS

  METHOD setTravelId.

*  Read the Entity Travel

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TravelId ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

*   DELETE The Existing Record where TravelID is arready Existing

    DELETE lt_travel WHERE TravelId IS NOT INITIAL.

    SELECT SINGLE FROM z23_travel_i FIELDS MAX( TravelId ) INTO @DATA(lv_travelid_max).

*ModiFY EML
    MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( TravelId )
    WITH VALUE #( FOR ls_travel_Id IN lt_travel INDEX INTO lv_index
                ( %tky = ls_travel_id-%tky
                  TravelId = lv_travelid_max + lv_index )
                ).

  ENDMETHOD.

  METHOD setOverallStatus.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_status).

    DELETE lt_status WHERE OverallStatus IS NOT INITIAL.

    MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR ls_status IN lt_status
                ( %tky = ls_status-%tky
                  OverallStatus = 'O' )
                ).


  ENDMETHOD.

  METHOD AcceptTravel.


    MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                    OverallStatus = 'A' ) ).

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %param = travel
                                            ) ).

  ENDMETHOD.

  METHOD RejectTravel.

    MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                OverallStatus = 'R' ) ).

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %param = travel
                                            ) ).

  ENDMETHOD.

  METHOD DeductDiscount.

    DATA : travel_for_update TYPE TABLE FOR UPDATE z23_travel_i .

    DATA(keys_temp) = keys.

    LOOP AT keys_temp ASSIGNING FIELD-SYMBOL(<key_temp>) WHERE %param-discount_percent IS INITIAL OR
                                                               %param-discount_percent > 100 OR
                                                               %param-discount_percent < 0.

      APPEND VALUE #( %tky = <key_temp>-%tky )  TO failed-travel.
      APPEND VALUE #( %tky = <key_temp>-%tky
                      %msg = new_message_with_text( text = 'Invalid Discount Percentage'
                                                    severity = if_abap_behv_message=>severity-error )
                     %element-totalprice = if_abap_behv=>mk-on
                     %action-deductdiscount = if_abap_behv=>mk-on ) TO reported-travel.

      DELETE keys_temp.

    ENDLOOP.

    CHECK keys_temp IS NOT INITIAL.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TotalPrice )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

    DATA : lv_percentage TYPE decfloat16.

    LOOP AT lt_travels ASSIGNING FIELD-SYMBOL(<fs_travel>).

      DATA(lv_discount_percent) = keys[ KEY id %tky = <fs_travel>-%tky ]-%param-Discount_Percent.
      lv_percentage = lv_discount_percent / 100.

      DATA(reduced_value) = <fs_travel>-TotalPrice * lv_percentage.

      reduced_value = <fs_travel>-TotalPrice - reduced_value.

      APPEND VALUE #( %tky = <fs_travel>-%tky
                      totalprice = reduced_value ) TO travel_for_update.

    ENDLOOP.

    MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( TotalPrice )
    WITH travel_for_update.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel_updated).

    result = VALUE #( FOR ls_travel IN lt_travel_updated ( %tky = ls_travel-%tky
                                                           %param = ls_travel ) ).

  ENDMETHOD.

  METHOD GetDefaultsForDeductDiscount.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( TotalPrice )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).

      IF travel-TotalPrice >= 5000.
        APPEND VALUE #( %tky = travel-%tky
                        %param-discount_percent = 30 ) TO result.
      ELSE.
        APPEND VALUE #( %tky = travel-%tky
                     %param-discount_percent = 15 ) TO result.
      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD recalctotalprice.

    TYPES : BEGIN OF ty_amount_per_currencycode,

              amount        TYPE /dmo/total_price,
              currency_code TYPE /dmo/currency_code,

            END OF ty_AMOUNT_PER_CURRENCYCODE.

    DATA : amounts_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE ENTITY Travel
    FIELDS ( BookingFee CurrencyCode )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel BY \_Booking
    FIELDS ( FlightPrice CurrencyCode )
    WITH CORRESPONDING #( travels )
    RESULT DATA(bookings)
    LINK DATA(booking_links).

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Booking BY \_BookingSupplement
    FIELDS ( Price CurrencyCode )
    WITH CORRESPONDING #( bookings )
    RESULT DATA(bookingsupliments)
    LINK DATA(bookingsupliments_links).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      amounts_per_currencycode = VALUE #( ( amount = <travel>-BookingFee
                                            currency_code = <travel>-CurrencyCode ) ).

      LOOP AT booking_links INTO DATA(booking_link) USING KEY id WHERE source-%tky = <travel>-%tky.

        DATA(booking) = bookings[ KEY id %tky = booking_link-target-%tky ].
        COLLECT VALUE ty_amount_per_currencycode( amount = booking-flightprice
                                                  currency_code = booking-currencycode ) INTO amounts_per_currencycode.


        LOOP AT bookingsupliments_links INTO DATA(bookingsupliments_link) USING KEY id WHERE source-%tky = booking-%tky.

          DATA(bookingsupplement) = bookingsupliments[ KEY id %tky = bookingsupliments_link-target-%tky ].

        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

    DELETE amounts_per_currencycode WHERE currency_code IS INITIAL.

    "    TRAVEL  USD -> PARENT - TOTAL PRICE
    "    BOOKING EUR -> USD
    "    BOOKING SUPPL EUR -> USD
    LOOP AT amounts_per_currencycode INTO DATA(amount_per_currencycode).

      IF <travel>-CurrencyCode = amount_per_currencycode-currencY_CODE.

        <travel>-TotalPrice += amount_per_currencycode-amount.

      ELSE.

        /dmo/cl_flight_amdp=>convert_currency(
             EXPORTING
                 iv_amount               = amount_per_currencycode-amount
                 iv_currency_code_source = amount_per_currencycode-currency_code
                 iv_currency_code_target = <travel>-CurrencyCode
                 iv_exchange_rate_date   = cl_abap_context_info=>get_system_date(  )
             IMPORTING
                 ev_amount = DATA(totAL_BOOKING_PRICE_PER_CURR) ).

        <travel>-TotalPrice += total_booking_price_per_curr.

      ENDIF.

      MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
      ENTITY Travel
      UPDATE FIELDS ( TotalPrice )
      WITH CORRESPONDING #( travels ).

    ENDLOOP.



  ENDMETHOD.

  METHOD CalculateTotalPrice.

    MODIFY ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    EXECUTE recalctotalprice
    FROM CORRESPONDING #( keys ).

  ENDMETHOD.

  METHOD ValidateCustomer.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( CustomerId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(Travels).

    DATA : customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.
    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).

    SELECT FROM /dmo/customer FIELDS customer_id
    FOR ALL ENTRIES IN @customers
    WHERE customer_id = @customers-customer_id
    INTO TABLE @DATA(validatecustomers).

    LOOP AT travels INTO DATA(travel).
      APPEND VALUE #( %tky = travel-%tky
                      %state_area = 'Validate Customer' ) TO reported-travel.

      IF travel-CustomerId IS NOT INITIAL AND NOT line_exists( validatecustomers[ customer_id = travel-CustomerId ]  ) .

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = |Not A Valid Customer { travel-CustomerId } | )
                        %element-customerid = if_abap_behv=>mk-on )  TO reported-travel.

      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD ValidateAgency.

  READ ENTITIES OF z23_travel_i IN LOCAL MODE
  ENTITY Travel
  FIELDS ( AgencyId )
  WITH CORRESPONDING #( keys )
  RESULT DATA(Travels).

    DATA : Agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id.
    Agencies = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING agency_id = AgencyId EXCEPT * ).

    SELECT FROM /dmo/agency FIELDS agency_id
    FOR ALL ENTRIES IN @agencies
    WHERE agency_id = @agencies-agency_id
    INTO TABLE @DATA(valideAgencies).

    LOOP AT travels INTO DATA(travel).

      IF travel-AgencyId IS NOT INITIAL AND NOT line_exists( valideagencies[ agency_id = travel-AgencyId ]  ) .

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = |Not A Valid AgencyId { travel-CustomerId } | )
                       %element-customerid  = if_abap_behv=>mk-on )  TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD ValidateDates.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).

      IF travel-BeginDate IS INITIAL.

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = |Begin Date Should not be blank| )
                       %element-begindate   = if_abap_behv=>mk-on )  TO reported-travel.


      ENDIF.

      IF travel-EndDate IS INITIAL.

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = |End Date Should not be blank| )
                       %element-enddate     = if_abap_behv=>mk-on )  TO reported-travel.

      ENDIF.

      IF travel-EndDate < travel-BeginDate AND travel-BeginDate IS NOT INITIAL AND travel-EndDate IS NOT INITIAL.

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = travel-%tky
                        %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = |End Date Should not be lessthan BeginDate| )
                       %element-begindate   = if_abap_behv=>mk-on )  TO reported-travel.

      ENDIF.



    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF z23_travel_i IN LOCAL MODE
    ENTITY Travel
    FIELDS ( OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    result = VALUE #( FOR ls_travel IN travels
                    ( %tky = ls_travel-%tky
                      %field-BookingFee    = COND #( WHEN ls_travel-OverallStatus = 'A'
                                                     THEN if_abap_behv=>fc-f-read_only
                                                     ELSE if_abap_behv=>fc-f-unrestricted )

                      %action-AcceptTravel = COND #( WHEN ls_travel-OverallStatus = 'R'
                                                     THEN if_abap_behv=>fc-o-disabled
                                                     ELSE if_abap_behv=>fc-o-enabled )

                      %action-RejectTravel = COND #( WHEN ls_travel-OverallStatus = 'A'
                                                     THEN if_abap_behv=>fc-o-disabled
                                                     ELSE if_abap_behv=>fc-o-enabled )
                    )  ).




  ENDMETHOD.

ENDCLASS.
