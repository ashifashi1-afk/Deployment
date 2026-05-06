@isTest
public class CaseContactMatcherTest {

    @testSetup
    static void setupData() {

        // Create Account (optional but good practice for Case)
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        // Create Contact
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            MailingPostalCode = '600001',
            AccountId = acc.Id
        );
        insert con;

        // Create Case linked to Contact
        Case cs = new Case(
            Subject = 'Test Case',
            Status = 'New',
            ContactId = con.Id
        );
        insert cs;

        // Store CaseNumber for reference (no need to update)
    }

    // ===== SUCCESS SCENARIO =====
    @isTest
    static void testMatchSuccess() {

        Case cs = [SELECT CaseNumber, Contact.FirstName FROM Case LIMIT 1];

        CaseContactMatcher.Request req = new CaseContactMatcher.Request();
        req.firstName = 'John';
        req.lastName = 'Doe';
        req.postalCode = '600001';
        req.requestNumber = cs.CaseNumber;

        Test.startTest();
        List<CaseContactMatcher.Response> result =
            CaseContactMatcher.matchCaseContact(new List<CaseContactMatcher.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('Match Found', result[0].message);
        System.assertNotEquals(null, result[0].caseStatus);
    }

    // ===== NO CONTACT FOUND =====
    @isTest
    static void testNoContact() {

        CaseContactMatcher.Request req = new CaseContactMatcher.Request();
        req.firstName = 'Invalid';
        req.lastName = 'User';
        req.postalCode = '999999';
        req.requestNumber = '000000';

        Test.startTest();
        List<CaseContactMatcher.Response> result =
            CaseContactMatcher.matchCaseContact(new List<CaseContactMatcher.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assert(result[0].message.contains('could not verify'));
    }

    // ===== NO CASE FOUND =====
    @isTest
    static void testNoCaseFound() {

        Contact con = [SELECT FirstName, LastName, MailingPostalCode FROM Contact LIMIT 1];

        CaseContactMatcher.Request req = new CaseContactMatcher.Request();
        req.firstName = con.FirstName;
        req.lastName = con.LastName;
        req.postalCode = con.MailingPostalCode;
        req.requestNumber = 'INVALID_CASE_123';

        Test.startTest();
        List<CaseContactMatcher.Response> result =
            CaseContactMatcher.matchCaseContact(new List<CaseContactMatcher.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assert(result[0].message.contains('could not verify'));
    }

    // ===== BULK TEST =====
    @isTest
    static void testBulkRequests() {

        Case cs = [SELECT CaseNumber FROM Case LIMIT 1];
        Contact con = [SELECT FirstName, LastName, MailingPostalCode FROM Contact LIMIT 1];

        CaseContactMatcher.Request req1 = new CaseContactMatcher.Request();
        req1.firstName = con.FirstName;
        req1.lastName = con.LastName;
        req1.postalCode = con.MailingPostalCode;
        req1.requestNumber = cs.CaseNumber;

        CaseContactMatcher.Request req2 = new CaseContactMatcher.Request();
        req2.firstName = 'Fake';
        req2.lastName = 'User';
        req2.postalCode = '000000';
        req2.requestNumber = 'WRONG';

        Test.startTest();
        List<CaseContactMatcher.Response> result =
            CaseContactMatcher.matchCaseContact(
                new List<CaseContactMatcher.Request>{ req1, req2 }
            );
        Test.stopTest();

        System.assertEquals(2, result.size());
    }
}