var klaroConfig = {
    htmlTexts: true,
    embedded: false,
    cookieExpiresAfterDays: 30,
    default: false,
    mustConsent: false,
    acceptAll: true,
    hideLearnMore: true,
    translations: {
    en: {
        privacyPolicyUrl: 'https://cdlib.org/about/policies-and-guidelines/privacy-statement/',
        consentNotice: {
        description:
            '<h1>Cookie Settings</h1><p>The California Digital Library uses cookies to ensure you have the best experience on our website. ' +
            'You can manage which cookies you want us to use.</p><p>Our <a href=https://cdlib.org/about/policies-and-guidelines/privacy-statement/ target=_blank>Privacy Statement</a> includes ' +
            'more details on the <a href="https://cdlib.org/about/policies-and-guidelines/privacy-policy/#cookie-notice" target="_blank">cookies we use</a> and how we protect your privacy.<p>'
        },
        consentModal: {
        // Klaro's consent modal is not used at CDL.
        },
        decline: 'Allow only necessary cookies',
        ok: 'Allow all cookies',
        purposes: {
        analytics: {
            title: 'Analytics'
        },
        security: {
            title: 'Security'
        },
        livechat: {
            title: 'Livechat'
        },
        advertising: {
            title: 'Advertising'
        },
        styling: {
            title: 'Styling'
        }
        }
    }
    },
    services: [
    {
        name: 'session',
        required: true,
        optOut: false,
        purposes: ['User Session management'],
        cookies: [
        '_mrt-dash_session', 'aws-waf-token'
        ],
    }
    ],
    callback: function (consent, service) {
    console.log(
        'User consent for service ' + service.name + ': ' + consent
    )
    }
}