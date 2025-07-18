import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getContactInfo from '@salesforce/apex/PSG_ReservationFromWizardController.getContactInfo';
import getProduct2 from '@salesforce/apex/PSG_ReservationFromWizardController.getProduct2';
import getNationalities from '@salesforce/apex/PSG_ReservationFromWizardController.getNationalities';
import getBankNames from '@salesforce/apex/PSG_ReservationFromWizardController.getBankNames';
import updateContactInfo from '@salesforce/apex/PSG_ReservationFromWizardController.updateContactInfo';
import getPaymentFormData from '@salesforce/apex/PSG_ReservationFromWizardController.getPaymentFormData';
import VISA_IMG from '@salesforce/resourceUrl/visa';
import VISA_SECURE_IMG from '@salesforce/resourceUrl/visaSecure';
import MASTERCARD_ID_CHECK_IMG from '@salesforce/resourceUrl/mastercardIdCheck';
import MASTERCARD_IMG from '@salesforce/resourceUrl/mastercard';
import createPaymentValidation from '@salesforce/apex/PSG_ReservationFromWizardController.createPaymentValidation';

const optsCurrency = [
    { label: 'USD', value: 'USD' },
    { label: 'EUR', value: 'EUR' },
    { label: 'DOP', value: 'DOP' },
]

const optsMainActivity = [
    { label: "Empleado/Employee", value: "Empleado/Employee" },
    { label: "Propietario/Owner	", value: "Propietario/Owner	" },
    { label: "Jubilado/Retired", value: "Jubilado/Retired" },
    { label: "Empleado publico/Public Employee", value: "Empleado publico/Public Employee" },
    { label: "Otros/Other", value: "Otros/Other" },
];

const optsSourceOfFunds = [
    { label: "Negocios/Business activity", value: "Negocios/Business activity" },
    { label: "Recursos propios/Savings/Family assets	", value: "Recursos propios/Savings/Family assets	" },
    { label: "Herencia/Inheritance", value: "Herencia/Inheritance" },
    { label: "Otros/Other", value: "Otros/Other" },
]

const optsTipoCuenta = [
    { label: "Cuenta corriente", value: "Cuenta corriente" },
    { label: "Cuenta de ahorro", value: "Cuenta de ahorro" },
]

const LATIN_AMERICAN_COUNTRIES = [
    { label: "República Dominicana", value: "1", format: "(###) ###-####", length: 10, maxLength: 14 },
    { label: "Estados Unidos", value: "+1", format: "(###) ###-####", length: 10, maxLength: 14 },
    { label: "Mexico", value: "+52", format: "(##) ####-####", length: 10, maxLength: 14 },
    { label: "Argentina", value: "+54", format: "(##) ####-####", length: 10, maxLength: 14 },
    { label: "Colombia", value: "+57", format: "(###) ###-####", length: 10, maxLength: 14 },
    { label: "Bolivia", value: "+591", format: "####-####", length: 8, maxLength: 9 },
    { label: "Chile", value: "+56", format: "(##) ####-####", length: 9, maxLength: 14 },
    { label: "Costa Rica", value: "+506", format: "###-####", length: 8, maxLength: 9 },
    { label: "Cuba", value: "+53", format: "(###) ###-####", length: 10, maxLength: 14 },
    { label: "Ecuador", value: "+593", format: "(##) ###-####", length: 9, maxLength: 13 },
    { label: "El Salvador", value: "+503", format: "####-####", length: 8, maxLength: 9 },
    { label: "Guatemala", value: "+502", format: "####-####", length: 8, maxLength: 9 },
    { label: "Honduras", value: "+504", format: "####-####", length: 8, maxLength: 9 },
    { label: "Nicaragua", value: "+505", format: "####-####", length: 8, maxLength: 9 },
    { label: "Panama", value: "+507", format: "###-####", length: 7, maxLength: 8 },
    { label: "Paraguay", value: "+595", format: "(###) ###-####", length: 10, maxLength: 14 },
    { label: "Peru", value: "+51", format: "(##) ###-####", length: 9, maxLength: 13 },
    { label: "Spain", value: "+34", format: "### ### ###", length: 9, maxLength: 11 },
    { label: "Uruguay", value: "+598", format: "(###) ###-###", length: 9, maxLength: 13 },
    { label: "Venezuela", value: "+58", format: "(###) ###-####", length: 10, maxLength: 14 }
];

export default class reservationFormWizard extends LightningElement {
    @api recordId;
    @track showRefundModal = false;
    @track showDeliveryModal = false;
    @track showPrivacyModal = false;
    @track showSecurityModal = false;

    @track selectedPaymentMethod = '';
    step = 1;
    latin_american_countries = LATIN_AMERICAN_COUNTRIES;
    countryOptions = LATIN_AMERICAN_COUNTRIES.map(country => ({
        label: country.label,
        value: country.value
    }));

    // 
    @track isCreditCard = true;
    @track isBankTransfer = false;
    @track isPaymentApproved = false;
    @track isPaymentDeclined = false;

    // Personal Information
    firstName = '';
    lastName = '';
    identificationNumber = '';
    email = '';
    phone = '';
    MobilePhone = '';


    //Product2 OBJ
    @track
    product2 = {};

    //Payment Validation
    @track
    paymentValidation = {};

    //FIle Docuement
    fileUploaded = {};

    formData = {};
    reservationAmount = 0;

    // Payment Information
    cardFormat = '####-####-####-####';
    cardFormatLength = 19;
    cardFormatCvc = '###';
    cardFormatCvcLength = 3;
    cardFormatExpiry = '##/##';
    cardFormatExpiryLength = 5;
    cardName = '';
    cardNumber = '';
    cardExpiry = '';
    cardCvc = '';

    // Additional Personal Information
    nationality = 'Dominican';
    maritalStatus = 'soltero';
    birthDate = '';
    profession = '';
    isOwner = false;
    occupationDetails = '';


    //spouse Information
    spouseName = '';
    spouseLastName = '';
    spouseIdNumber = '';
    spouseBirthPlace = '';
    spouseNationality = 'Dominican';
    spouseProfession = '';
    spouseProfessionDetail = '';

    // Nuevas propiedades para campos adicionales
    hasOtherCitizenship = 'No';
    otherCitizenship = '';
    address = '';
    city = '';
    state = '';
    postalCode = '';

    //ingresos
    businessName = '';
    businessActivity = '';
    businessPhone = '';
    businessAddress = '';
    businessOcupation = '';
    businessSupervisor = '';
    sourceOfFunds = '';
    anotherSourceOfFunds = '';
    mainActivity = '';
    lastOcupation = '';
    anotherActivity = '';
    anotherSourceOfFundsDisabled = true;
    anotherActivityDisabled = true;
    businessSelectedCountry = this.latin_american_countries[0];
    businessCountryCode = this.businessSelectedCountry.value;
    businessPhonePlaceholder = this.businessSelectedCountry.format;
    businessPhoneMaxLength = this.businessSelectedCountry.maxLength;

    // Referencias
    nombreBanco = '';
    howHeard = '';
    otherHowHeard = '';
    nombresBancos = [];
    accountNo = '';
    tipoCuenta = '';
    bankBranch = '';
    bankPhone = '';

    comercialReferralName = '';
    comercialContactName = '';
    comercialReferralAddress = '';
    comercialReferralPhone = '';
    laboralReferralName = '';
    laboralReferralOcupation = '';
    laboralReferralPhone = '';

    politicallyExposed = '';
    linkWithPolitician = '';
    relationshipWithPolitician = '';
    otherLink = '';

    politicianParentheses = '';
    politicianName = '';
    politicianPosition = '';
    politicianInstitution = '';

    //GlobalPickList Info
    nationalities = [];
    optsCurrency = optsCurrency;
    optsMainActivity = optsMainActivity;
    optsTipoCuenta = optsTipoCuenta;
    optsSourceOfFunds = optsSourceOfFunds;

    selectedCountry = this.latin_american_countries[0];
    phonePlaceholder = this.selectedCountry.format;
    countryCode = this.selectedCountry.value;
    maxPhoneLength = this.selectedCountry.maxLength;
    identificationMaxLengh = 13;
    customerId = '';
    customerInfo = {};

    identificationType = 'C';
    identificationTypeOptions = [
        { label: 'Cédula', value: 'C' },
        { label: 'Pasaporte', value: 'P' },
        { label: 'RNC', value: 'R' }
    ];

    isLoading = false;
    errorMessage = '';

    @wire(CurrentPageReference)
    currentPageReference;

    get maritalStatusOptions() {
        return [
            { label: 'Soltero', value: 'soltero' },
            { label: 'Viudo/a', value: 'viudo' },
            { label: 'Casado/a', value: 'casado' },
            { label: 'Unión libre', value: 'union_libre' },
        ];
    }

    // Nuevas opciones para combobox de ciudadanía
    get citizenshipOptions() {
        return [
            { label: 'Sí', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }

    get optsHowHeard() {
        return [
            { label: 'Cliente / Client', value: 'Cliente / Client' },
            { label: 'Motor de búsqueda / Search engine', value: 'Motor de búsqueda / Search engine' },
            { label: 'Otros / Other', value: 'Otros / Other' }
        ];
    }

    get optspoliticallyExposed() {
        return [
            { label: 'SI', value: 'SI' },
            { label: 'No', value: 'No' }
        ];
    }

    get optslinkWithPolitician() {
        return [
            { label: 'Pariente cercano / Next of kin', value: 'Pariente cercano / Next of kin' },
            { label: 'Asociado/ Close associate', value: 'Asociado/ Close associate' },
            { label: 'Otro / Other', value: 'Otro / Other' }
        ];
    }


    get optsrelationshipWithPolitician() {
        return [
            { label: 'Sí/Yes', value: 'Sí/Yes' },
            { label: 'No', value: 'No' }
        ];
    }

    get paymentMethodOptions() {
        return [
            {
                label: 'Pago con Tarjeta de Crédito',
                value: 'creditCard'
            },
            {
                label: 'Transferencia Bancaria',
                value: 'bankTransfer'
            }
        ];
    }

    get isNextDisabled() {
        return !this.selectedPaymentMethod;
    }


    connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        const status = urlParams.get('status');

        console.log(status);
        if (status === 'cancelled') {
            this.isCreditCard = true;
            this.step = 7;
        } else if (status === 'approved') {
            this.isPaymentApproved = true;
            this.step = 8;
        } else if (status === 'declined') {
            this.isPaymentDeclined = true;
            this.step = 8;
        }

        this.recordId = this.currentPageReference.state.c__recordId;
        // this.recordId = '006D300000BZ6QqIAL';

        console.log('recordId:', this.recordId);
        this.getContactInfo();
        this.getProduct2();
        this.getNationalities();
        this.getBankNames();
    }

    get VISA_IMG() {
        return VISA_IMG;
    }

    get MASTERCARD_IMG() {
        return MASTERCARD_IMG;
    }

    get MASTERCARD_ID_CHECK_IMG() {
        return MASTERCARD_ID_CHECK_IMG;
    }

    get VISA_SECURE_IMG() {
        return VISA_SECURE_IMG;
    }


    getContactInfo() {
        getContactInfo({ recordId: this.recordId })
            .then((result) => {
                this.customerId = result;
                console.log('Customer ID:', this.customerId);
            }).catch((error) => {
                console.error('Error fetching contact info:', error);
            });
    }


    getProduct2() {
        getProduct2({ recordId: this.recordId })
            .then((result) => {
                this.product2 = result;
                console.log('product2 data: ' + JSON.stringify(this.product2));
                this.reservationAmount = (parseInt(this.product2.reservationAmount, 10) / 100).toFixed(2);
                this.getPaymentFormData();
            }).catch((error) => {
                this.product2
                console.error('Error fetching product info:', error);
            });
    }


    getPaymentFormData() {
        getPaymentFormData({ oppId: this.recordId, orderNumber: this.recordId, amount: this.product2.reservationAmount })
            .then(result => {
                this.formData = result;
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }

    getNationalities() {
        getNationalities().then((result) => {
            this.nationalities = result.map((item) => ({ label: item, value: item }));
        })
    }

    getBankNames() {
        getBankNames().then((result) => {
            this.nombresBancos = result.map((item) => ({ label: item, value: item }));
        })
            .catch((error) => {
                console.error('Ha ocurrido un error al obtener los nombres de bancos: ', error);
            })
    }

    createPaymentValidation() {
        this.isLoading = true;
        this.paymentValidation.recordId = this.recordId;
        this.paymentValidation.customerId = this.customerId;
        createPaymentValidation({
            paymentValidation: this.paymentValidation,
            fileName: this.fileUploaded.filename,
            fileType: this.fileUploaded.filetype,
            fileBase64Body: this.fileUploaded.base64
        }).then((result) => {
            this.isLoading = false;
            console.log('PaymentValidation created successfully:', result);
            this.isPaymentApproved = true;
            this.nextStep();
            console.log('Se cambio al step: ', this.step);
            console.log('El valor de message es: ', this.isPaymentApproved, this.isPaymentDeclined);

        })
            .catch((error) => {
                this.product2
                console.error('Error fetching PaymentValidation info:', error);
            });
    }

    get isStep1() {
        return this.step === 1;
    }

    get isStep2() {
        return this.step === 2;
    }

    get isStep3() {
        return this.step === 3;
    }

    get isStep4() {
        return this.step === 4;
    }

    get isStep5() {
        return this.step === 5;
    }

    get isStep6() {
        return this.step === 6;
    }

    get isStep7() {
        return this.step === 7;
    }

    get isStep8() {
        return this.step === 8;
    }

    get currentStep() {
        return this.step.toString();
    }

    get showGeneralSubtitle() {
        return this.isStep1 || this.isStep2 || this.isStep3 || this.isStep4 || this.isStep5;
    }

    get otherCitizenRequired() {
        return this.hasOtherCitizenship == 'Yes'
    }

    get otherCitizenDisabled() {
        return this.hasOtherCitizenship !== 'Yes'
    }

    get otherHowHeardRequired() {
        return this.howHeard == 'Otros / Other'
    }

    get otherHowHeardDisabled() {
        return this.howHeard !== 'Otros / Other'
    }

    get politicianParenthesesRequired() {
        return this.linkWithPolitician == 'Pariente cercano / Next of kin'
    }

    get politicianParenthesesDisabled() {
        return this.linkWithPolitician !== 'Pariente cercano / Next of kin'
    }

    getIdentificationMaxLenght() {
        if (this.identificationType === 'C') {
            return 13;
        } else if (this.identificationType === 'P') {
            return 50;
        } else if (this.identificationType === 'R') {
            return 11;
        }
        return 0;
    }

    handleInput(event) {
        const field = event.target.dataset.field;
        // Para checkboxes, usa event.target.checked. Para otros, usa event.target.value.
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;

        if (field.includes('.')) {
            const [parent, child] = field.split('.');
            console.log("const [parent, child]", parent, child);
            this[parent][child] = value;
        }
        else {
            this[field] = value;
            console.log(this[field]);
        }
    }


    handleSourceOfFundsChange(event) {
        this.sourceOfFunds = event.target.value;
        this.anotherSourceOfFundsDisabled = this.sourceOfFunds !== 'Otros/Other';
        if (this.anotherSourceOfFundsDisabled) {
            this.anotherSourceOfFunds = '';
        }
    }

    handleMainActivityChange(event) {
        this.mainActivity = event.target.value;
        this.anotherActivityDisabled = this.mainActivity !== 'Otros/Other';
        if (this.anotherActivityDisabled) {
            this.anotherActivity = '';
        }
    }

    nombreBancoChange(event) {
        this.nombreBanco = event.target.value;
    }

    handletipoCuentaChange(event) {
        this.tipoCuenta = event.target.value;
    }

    handlePaymentMethodChange(event) {
        this.selectedPaymentMethod = event.detail.value;
    }

    handleHowHeardChange(event) {
        this.howHeard = event.detail.value;
    }

    handlepoliticallyExposedChange(event) {
        this.politicallyExposed = event.detail.value;
    }

    handlelinkWithPoliticianChange(event) {
        this.linkWithPolitician = event.detail.value;
        if (event.detail.value !== 'Pariente cercano / Next of kin') {
            this.politicianParentheses = '';
            this.politicianName = '';
            this.politicianPosition = '';
            this.politicianInstitution = '';
        }
    }

    handlerelationshipWithPoliticianChange(event) {
        this.relationshipWithPolitician = event.detail.value;
    }

    // Nuevo manejador para cambio de ciudadanía
    handleCitizenshipChange(event) {
        this.hasOtherCitizenship = event.detail.value;
        if (this.hasOtherCitizenship !== 'Yes') {
            this.otherCitizenship = '';
        }
    }

    handleFileUpload(event) {
        if (event.detail.files.length > 0) {
            const file = event.detail.files[0];
            const reader = new FileReader();
            reader.onload = () => {
                this.fileUploaded = {
                    filename: file.name,
                    filetype: file.type,
                    base64: reader.result.split(',')[1]
                };
            };
            reader.readAsDataURL(file);

        }
    }

    openRefundPolicy() {
        this.showRefundModal = true;
    }

    openDeliveryPolicy() {
        this.showDeliveryModal = true;
    }

    openPrivacyPolicy() {
        this.showPrivacyModal = true;
    }

    openSecurityModal() {
        this.showSecurityModal = true;
    }

    // Métodos para cerrar los modals
    closeRefundModal() {
        this.showRefundModal = false;
    }

    closeDeliveryModal() {
        this.showDeliveryModal = false;
    }

    closePrivacyModal() {
        this.showPrivacyModal = false;
    }

    closeSecurityModal() {
        this.showSecurityModal = false;
    }

    nextStep() {
        if (this.step < 8) {
            this.errorMessage = '';
            if (this.step === 2 && this.maritalStatus !== 'casado') {
                console.log('Marital status: ', this.maritalStatus);
                this.step = 4;
            } else {
                this.step++;
            }
        }
    }

    toStep7() {
        this.step = 7;
    }

    previousStep() {
        if (this.step > 1) {
            if (this.step === 4 && this.maritalStatus !== 'casado') {
                this.step = 2;
            } else {
                this.step--;
            }
        }
    }

    handleIdentificationTypeChange(event) {
        this.identificationType = event.target.value;
        this.identificationNumber = '';
    }

    handleDocumentChange(event) {
        this.identificationNumber = event.target.value;
        this.identificationMaxLengh = this.getIdentificationMaxLenght();
        // this.identificationNumber = this.identificationNumber.replace(/\D/g, '');
        // event.target.value = this.identificationNumber;
        //If this.identificationType is C, then the format is ###-#######-#
    }

    handleCountryChange(event) {
        this.selectedCountry = this.latin_american_countries.find(
            (country) => country.value == event.target.value
        );
        this.maxPhoneLength = this.selectedCountry.maxLength;
        this.phonePlaceholder = this.selectedCountry.format;
        this.phone = this.formatPhoneNumber(this.phone);
        this.MobilePhone = this.formatPhoneNumber(this.MobilePhone);
    }

    handleBusinessCountryChange(event) {
        this.businessSelectedCountry = this.latin_american_countries.find(
            (country) => country.value == event.target.value
        );
        this.businessPhoneMaxLength = this.businessSelectedCountry.maxLength;
        this.businessPhonePlaceholder = this.businessSelectedCountry.format;
        this.businessPhone = this.formatPhoneNumber(this.businessPhone);
    }

    handlePhoneChange(event) {
        this.phone = this.formatPhoneNumber(event.target.value);
    }

    handleMobilePhoneChange(event) {
        this.MobilePhone = this.formatPhoneNumber(event.target.value);
    }

    handleBankPhoneChange(event) {
        this.bankPhone = this.formatPhoneNumber(event.target.value);
    }

    handleComercialPhoneChange(event) {
        this.comercialReferralPhone = this.formatPhoneNumber(event.target.value);
    }

    handleLaboralPhoneChange(event) {
        this.laboralReferralPhone = this.formatPhoneNumber(event.target.value);
    }

    handleBusinessPhoneChange(event) {
        this.businessPhone = this.formatPhoneNumber(event.target.value);
    }

    formatPhoneNumber(value) {
        let cleanValue = value.replace(/\D/g, "");
        let format = this.selectedCountry ? this.selectedCountry.format : "###-###-####"; // Default format

        let formattedNumber = "";
        let j = 0;
        for (let i = 0; i < format.length && j < cleanValue.length; i++) {
            if (format[i] === "#") {
                formattedNumber += cleanValue[j];
                j++;
            } else {
                formattedNumber += format[i];
            }
        }
        return formattedNumber;
    }

    formatCardNumber(value) {
        let cleanValue = value.replace(/\D/g, "");
        let formattedNumber = "";
        for (let i = 0; i < cleanValue.length; i++) {
            if (i > 0 && i % 4 === 0) {
                formattedNumber += "-";
            }
            formattedNumber += cleanValue[i];
        }
        return formattedNumber;
    }

    formatCardCvc(value) {
        let cleanValue = value.replace(/\D/g, "");
        let formattedNumber = "";
        for (let i = 0; i < cleanValue.length; i++) {
            if (i > 0 && i % 3 === 0) {
                formattedNumber += "-";
            }
            formattedNumber += cleanValue[i];
        }
        return formattedNumber;
    }

    formatCardExpiry(value) {
        let cleanValue = value.replace(/\D/g, "");
        let formattedNumber = "";
        for (let i = 0; i < cleanValue.length; i++) {
            if (i === 2) {
                formattedNumber += "/";
            }
            formattedNumber += cleanValue[i];
        }
        return formattedNumber;
    }

    handleCardNumberChange(event) {
        this.cardNumber = this.formatCardNumber(event.target.value);
    }

    handleCardCvcChange(event) {
        this.cardCvc = this.formatCardCvc(event.target.value);
    }

    handleCardExpiryChange(event) {
        this.cardExpiry = this.formatCardExpiry(event.target.value);
    }

    handlePaymentValidation(event) {
        event.preventDefault(); // Evita el refresh de la página

        if (this.fileUploaded) {
            this.createPaymentValidation();
        }

    }


    // metodo para ir al siguiente step según el método seleccionado
    handleMoveToPaymentMethod() {
        if (this.selectedPaymentMethod) {
            if (this.selectedPaymentMethod === 'creditCard') {
                this.isCreditCard = true;
                this.isBankTransfer = false;
                this.nextStep();
            } else if (this.selectedPaymentMethod === 'bankTransfer') {
                this.isBankTransfer = true;
                this.isCreditCard = false;
                this.nextStep();
            }
        }
    }

    handleNextStepWithoutValidationEvent(event) {
        this.nextStep();
    }

    handleValidateContact(event) {
        event.preventDefault();

        if (!this.isValidMoveForward()) {
            this.errorMessage = 'Por favor llenar todos los campos requeridos.';
            return;
        }

        this.nextStep();

    }

    handleValidateReferences(event) {
        event.preventDefault();

        if (!this.isValidMoveForward()) {
            this.errorMessage = 'Por favor llenar todos los campos requeridos.';
            return;
        }

        if (this.step === 5) {
            this.handleSubmitContact(event);
        } else {
            this.nextStep();
        }

    }

    handleSubmitContact(event) {
        this.isLoading = true;
        this.errorMessage = '';
        const data = {
            opptyId: this.recordId,
            id: this.customerId,
            //Informacion Personal
            firstName: this.firstName,
            lastName: this.lastName,
            identificationType: this.identificationType,
            identificationNumber: this.identificationNumber,
            email: this.email,
            phone: this.phone,
            MobilePhone: this.MobilePhone,
            nationality: this.nationality,
            maritalStatus: this.maritalStatus,
            birthDate: this.birthDate,
            profession: this.profession,
            isOwner: this.isOwner,
            occupationDetails: this.occupationDetails,
            hasOtherCitizenship: this.hasOtherCitizenship,
            otherCitizenship: this.otherCitizenship,
            address: this.address,
            city: this.city,
            state: this.state,
            postalCode: this.postalCode,

            //Spouse
            spouseName: this.spouseName,
            spouseLastName: this.spouseLastName,
            spouseIdNumber: this.spouseIdNumber,
            spouseBirthPlace: this.spouseBirthPlace,
            spouseNationality: this.spouseNationality,
            spouseProfession: this.spouseProfession,
            spouseProfessionDetail: this.spouseProfessionDetail,

            // Fuente de ingresos
            sourceOfFunds: this.sourceOfFunds,
            anotherSourceOfFunds: this.anotherSourceOfFunds,
            mainActivity: this.mainActivity,
            lastOcupation: this.lastOcupation,
            anotherActivity: this.anotherActivity,
            businessName: this.businessName,
            businessActivity: this.businessActivity,
            businessPhone: this.businessPhone,
            businessAddress: this.businessAddress,
            businessOcupation: this.businessOcupation,
            businessSupervisor: this.businessSupervisor,

            // referencias
            howHeard: this.howHeard,
            otherHowHeard: this.otherHowHeard,
            nombreBanco: this.nombreBanco,
            accountNo: this.accountNo,
            tipoCuenta: this.tipoCuenta,
            bankBranch: this.bankBranch,
            bankPhone: this.bankPhone,
            comercialReferralName: this.comercialReferralName,
            comercialContactName: this.comercialContactName,
            comercialReferralAddress: this.comercialReferralAddress,
            comercialReferralPhone: this.comercialReferralPhone,
            laboralReferralName: this.laboralReferralName,
            laboralReferralOcupation: this.laboralReferralOcupation,
            laboralReferralPhone: this.laboralReferralPhone,
            politicallyExposed: this.politicallyExposed,
            linkWithPolitician: this.linkWithPolitician,
            relationshipWithPolitician: this.relationshipWithPolitician,
            otherLink: this.otherLink,
            politicianParentheses: this.politicianParentheses,
            politicianName: this.politicianName,
            politicianPosition: this.politicianPosition,
            politicianInstitution: this.politicianInstitution
        };

        console.log('Data to be sent:', JSON.stringify(data));

        updateContactInfo({ info: JSON.stringify(data) })
            .then((result) => {
                console.log('Contact info updated successfully:', result);
                this.isLoading = false;
                this.nextStep();
            })
            .catch((error) => {
                console.error('Error updating contact info:', error);
                this.isLoading = false;
                this.errorMessage = 'Ha ocurrido un error al actualizar la información de contacto.';
            });

    }

    handleSubmitPayment(event) {
        this.isLoading = true;
        if (this.step === 2 && !this.isStep2Valid()) {
            this.isLoading = false;
            this.errorMessage = 'Por favor llenar todos los campos requeridos.';
            return;
        }

        updateOpportunityStage({ recordId: this.recordId, stage: 'Reserva' })
            .then((result) => {
                console.log('Opportunity stage updated successfully:', result);
                this.isLoading = false;
                this.nextStep();
            })
            .catch((error) => {
                console.error('Error updating opportunity stage:', error);
                this.isLoading = false;
                this.errorMessage = 'Ha ocurrido un error al intentar reservar su unidad.';
            });
    }

    isValidMoveForward() {
        if (this.step === 2) {
            return this.isStep2Valid();
        } else if (this.step === 3) {
            return this.isStep3Valid();
        } else if (this.step === 4) {
            return this.isStep4Valid();
        } else if (this.step === 5) {
            return this.isStep5Valid();
        }
        return true;
    }

    // Actualizar validación de paso 1
    isStep2Valid() {
        return this.firstName &&
            this.lastName &&
            this.identificationNumber &&
            this.email &&
            this.phone &&
            this.MobilePhone &&
            this.address &&
            this.city &&
            this.state &&
            this.postalCode &&
            this.nationality &&
            this.maritalStatus &&
            this.birthDate &&
            this.profession &&
            this.occupationDetails &&
            this.hasOtherCitizenship &&
            (
                this.hasOtherCitizenship !== 'Yes' ||
                (this.hasOtherCitizenship === 'Yes' && this.otherCitizenship)
            );
    }

    isStep3Valid() {
        return this.spouseName &&
            this.spouseLastName &&
            this.spouseIdNumber &&
            this.spouseBirthPlace &&
            this.spouseNationality &&
            this.spouseProfession &&
            this.spouseProfessionDetail;
    }

    isStep4Valid() {
        return this.businessName &&
            this.businessActivity &&
            this.businessPhone &&
            // this.businessAddress &&
            this.businessOcupation &&
            this.businessSupervisor &&
            this.sourceOfFunds &&
            this.mainActivity &&
            this.lastOcupation

    }

    isStep5Valid() {
        return this.howHeard &&
            (
                !this.otherHowHeardRequired ||
                (this.otherHowHeardRequired && this.otherHowHeard)
            ) &&
            this.nombreBanco &&
            this.accountNo &&
            this.tipoCuenta &&
            this.bankBranch &&
            this.bankPhone &&
            this.comercialReferralName &&
            this.comercialContactName &&
            this.comercialReferralAddress &&
            this.comercialReferralPhone &&
            this.laboralReferralName &&
            this.laboralReferralOcupation &&
            this.laboralReferralPhone &&
            this.politicallyExposed &&
            this.linkWithPolitician &&
            this.relationshipWithPolitician &&
            this.otherLink &&
            (
                !this.politicianParenthesesRequired ||
                (this.politicianParenthesesRequired && 
                    this.politicianParentheses &&
                    this.politicianName &&
                    this.politicianPosition &&
                    this.politicianInstitution
                )
            )

    }
}