/**
 * @description       : 
 * @author            : JH Moon
 * @last modified on  : 07-11-2025
 * @last modified by  : Hyowon Hong
**/
trigger OrderTrigger on Order (after insert, after update, before insert) {
    TriggerManager.prepare()
        .bind(new OrderTriggerHandler())
        .execute();
}