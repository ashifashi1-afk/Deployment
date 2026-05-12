public with sharing class CaseContactMatcher {

    // ===== INPUT CLASS =====
    public class Request {
        @InvocableVariable(required=true)
        public String firstName;

        @InvocableVariable(required=true)
        public String lastName;

        @InvocableVariable(required=true)
        public String postalCode;

        @InvocableVariable(required=true)
        public String requestNumber; // CaseNumber
    }

    // ===== OUTPUT CLASS112=====
    public class Response {
        @InvocableVariable
        public String caseStatus;

        @InvocableVariable
        public String service;

        @InvocableVariable
        public String message;
    }

    // ===== MAIN METHOD/1 =====
    @InvocableMethod(label='Match Case and Contact' description='Match using Name + PostalCode + Request Number')
    public static List<Response> matchCaseContact(List<Request> requestList) {

        List<Response> responseList = new List<Response>();

        for (Request req : requestList) {

            Response res = new Response();

            try {

                // Step 1: Find Contact
                List<Contact> contacts = [
                    SELECT Id, FirstName, LastName, MailingPostalCode
                    FROM Contact
                    WHERE FirstName = :req.firstName
                    AND LastName = :req.lastName
                    AND MailingPostalCode = :req.postalCode
                    LIMIT 1
                ];

                if (contacts.isEmpty()) {
                    res.message = 'We could not verify your details. Please check the information and try again, or contact support.';
                    responseList.add(res);
                    continue;
                }

                Contact con = contacts[0];

                // Step 2: Find Case using Request Number + Contact
                List<Case> cases = [
                    SELECT Id, Status, Services_Date__c, CaseNumber
                    FROM Case
                    WHERE CaseNumber = :req.requestNumber
                    AND ContactId = :con.Id
                    LIMIT 1
                ];

                if (cases.isEmpty()) {
                    res.message = 'We could not verify your details. Please check the information and try again, or contact support.';
                    responseList.add(res);
                    continue;
                }

                Case cs = cases[0];

                // Step 3: Success
                res.caseStatus = cs.Status;
                res.service = String.valueOf(cs.Services_Date__c);
                res.message = 'Match Found';

            } catch (Exception e) {
                res.message = 'Error: ' + e.getMessage();
            }

            responseList.add(res);
        }

        return responseList;
    }
}