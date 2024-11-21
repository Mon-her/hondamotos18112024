@IsTest
class fan_FlowStep2ValidateNextRunTest {

    @IsTest
    static void processRoutingSchedule() {
        fan_FlowStep2ValidateNextRun.testOrderItemSummaries = new OrderItemSummary[]{ new OrderItemSummary() };

        fan_FlowStep2ValidateNextRun.Request request = new fan_FlowStep2ValidateNextRun.Request();
        fan_FlowStep2ValidateNextRun.processRoutingSchedule(new fan_FlowStep2ValidateNextRun.Request[] { request });
    }
}