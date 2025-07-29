/**
 * @description       : 
 * @author            : Hyowon Hong
 * @last modified on  : 07-03-2025
 * @last modified by  : Hyowon Hong
**/
trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    TriggerManager.prepare()
    .bind(new AccountTriggerHandler())
    .execute();
}