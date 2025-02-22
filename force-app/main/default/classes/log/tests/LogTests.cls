@IsTest
private class LogTests {
	@IsTest
	private static void testDirectPublishMethodsPositive() {
		Test.startTest();
		Log.get().publish('This is a test');
		Log.get().publish(new DmlException('hi from exception land'));
		Test.stopTest();
		Test.getEventBus().deliver();
		String currentRequestId = Request.getCurrent().getRequestId();
		Quiddity currentQuiddity = Request.getCurrent().getQuiddity();
		List<LogEvent__c> events = [
			SELECT Id, Request_Id__c, Quiddity__c, Log_Data__c, Severity__c
			FROM LogEvent__c
			ORDER BY Severity__c
		];
		Assert.areEqual(
			2,
			events.size(),
			'expected to find only a single event'
		);

		for (LogEvent__c logEvt : events) {
			Assert.areEqual(
				currentRequestId,
				logEvt.Request_Id__c,
				'Expected the reuqest id to have been logged'
			);
			Assert.areEqual(
				currentQuiddity.name(),
				logEvt.Quiddity__c,
				'Expected quiddity on log message to match apex test context'
			);
			Assert.isTrue(
				new Set<String>{
						Quiddity.RUNTEST_ASYNC.name(),
						Quiddity.RUNTEST_DEPLOY.name(),
						Quiddity.RUNTEST_SYNC.name()
					}
					.contains(logEvt.Quiddity__c),
				'Expected quiddity to be one of the apex test types, found: ' +
				logEvt.Quiddity__c
			);
		}
	}

	@IsTest
	private static void testLogMultipleItemPositive() {
		Log logger = Log.get();
		Test.startTest();
		logger.add('testing add string method');
		logger.add('Testing 123', LoggingLevel.WARN);
		logger.add(new DmlException('hi from exception land'));
		logger.add(new DmlException('meh'), LoggingLevel.DEBUG);
		logger.publish();
		Test.stopTest();
		// Platform Events require this to push the event in a test env
		Test.getEventBus().deliver();

		String currentRequestId = Request.getCurrent().getRequestId();
		//this can't be hard-coded since apex test runs have multiple possible quiddity values
		Quiddity currentQuiddity = Request.getCurrent().getQuiddity();

		List<LogEvent__c> events = [
			SELECT Id, Request_Id__c, Quiddity__c, Log_Data__c, Severity__c
			FROM LogEvent__c
			ORDER BY Severity__c
		];

		Assert.areEqual(4, events.size(), 'Expected to find 3 records');

		for (LogEvent__c logEvt : events) {
			Assert.areEqual(
				currentRequestId,
				logEvt.Request_Id__c,
				'Expected the reuqest id to have been logged'
			);
			Assert.areEqual(
				currentQuiddity.name(),
				logEvt.Quiddity__c,
				'Expected quiddity on log message to match apex test context'
			);
			Assert.isTrue(
				new Set<String>{
						Quiddity.RUNTEST_ASYNC.name(),
						Quiddity.RUNTEST_DEPLOY.name(),
						Quiddity.RUNTEST_SYNC.name()
					}
					.contains(logEvt.Quiddity__c),
				'Expected quiddity to be one of the apex test types, found: ' +
				logEvt.Quiddity__c
			);

			//debug info warn error - proposed
		}

		Assert.isTrue(
			events[0].Log_Data__c.split('\n')[0]
				.containsIgnoreCase('Exception: [System.DMLException] meh'),
			'Expected the log data to contain [System.DMLException] meh'
		);
		//System.AssertException: Assertion Failed: Expected: Exception: [System.DmlException] meh , Actual: Exception: [System.DMLException] meh
	}
}
