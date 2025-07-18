public virtual class VF_Messages_Abstract {
    
    public void createError(ApexPages.Severity s, String message) {
        ApexPages.addMessage(new ApexPages.Message(s, string.escapeSingleQuotes(message.escapeJava())));
    }

    /**@description Indicates if a custom message is present*/
    public boolean hasMessages {
        get {
             return ApexPages.hasMessages();
        }
    }

    /**@description The custom error message */
    public String errorMessage {
        get {
            if (hasMessages) {
                return ApexPages.getMessages()[0].getDetail();
            }

            return null;
        }
    }

    /**@description The type of message: 'error' or 'success' */
    public string alertType {
        get {
            if (hasMessages) {
                return ApexPages.getMessages()[0].getSeverity() == ApexPages.Severity.CONFIRM ? 'success' : 'error';
            }

            return 'error';
        }
        private set;
    }

}