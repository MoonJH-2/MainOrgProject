/**
 * @description Asset 상태 업데이트를 위한 배치 클래스
 * @author AI Assistant
 * @created 2025-07-24
 */
public class AssetStatusUpdateBatch implements Schedulable {
    public void execute(SchedulableContext sc) {
        AssetStatusManagementService.updateAssetStatuses();
    }
}
