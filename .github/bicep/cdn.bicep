@minLength(3)
@maxLength(21)
param appName string

param primaryEndpointName string
param primaryEndpointHostName string

param customDomainName string = ''

@description('Resource tags for organizing / cost monitoring')
param tags object

var cdnProfileName = appName
var cdnEndpointName = appName
// setting a default so that the arm template validates the customDomain segment length (even though it shouldn't deploy)
var sanitizedCustomDomainHostName = empty(customDomainName) ? 'should-not-be-deployed' : toLower(customDomainName)
var sanitizedCustomDomainName = replace(sanitizedCustomDomainHostName, '.', '-')

resource cdnProfile 'Microsoft.Cdn/profiles@2020-09-01' = {
  name: cdnProfileName
  location: 'global'
  tags: tags
  sku: {
    name: 'Standard_Microsoft'
  }
  resource cdnEndpoint 'endpoints@2020-09-01' = {
    name: cdnEndpointName
    location: 'global'
    tags: tags
    properties: {
      isHttpAllowed: true
      isHttpsAllowed: true
      originHostHeader: primaryEndpointHostName
      queryStringCachingBehavior: 'IgnoreQueryString'
      optimizationType: 'GeneralWebDelivery'      
      origins: [
        {
          name: primaryEndpointName
          properties: {
            hostName: primaryEndpointHostName
          }
        }
      ]
      deliveryPolicy: {
        description: 'Default rules'
        rules: [
          {
            name: 'HttpToHttps'
            order: 1
            conditions: [
              {
                name: 'RequestScheme'
                parameters: {
                  '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleRequestSchemeConditionParameters'
                  operator: 'Equal'
                  matchValues: [
                    'HTTP'
                  ]
                }
              }
            ]
            actions: [
              {
                name: 'UrlRedirect'
                parameters: {
                  '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlRedirectActionParameters'
                  redirectType: 'Found'
                  destinationProtocol: 'Https'
                }
              }
            ]
          }
          {
            name: 'SpaRewrite'
            order: 2
            conditions: [
              {
                name: 'UrlFileExtension'
                parameters: {
                  '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlFileExtensionMatchConditionParameters'
                  operator: 'LessThan'
                  matchValues: [
                    '1'
                  ]
                }
              }
            ]
            actions: [
              {
                name: 'UrlRewrite'
                parameters: {
                  '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlRewriteActionParameters'
                  sourcePattern: '/'
                  destination: '/index.html'
                  preserveUnmatchedPath: false
                }
              }
            ]
          }
          {
            name: 'BypassIndexHtml'
            order: 3
            conditions: [
              {
                name: 'UrlFileName'
                parameters: {
                  '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlFilenameConditionParameters'
                  operator: 'BeginsWith'
                  matchValues: [
                    'index.html'
                  ]
                }
              }
            ]
            actions: [
              {
                name: 'CacheExpiration'
                parameters: {
                  '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleCacheExpirationActionParameters'
                  cacheBehavior: 'BypassCache'
                  cacheType: 'All'
                }
              }
            ]
          }
        ]
      }
    }
    resource cdnEndppointCustomDomain 'customDomains@2020-09-01' = if (!empty(customDomainName)) {
      name: sanitizedCustomDomainName
      properties: {
        hostName: sanitizedCustomDomainHostName
      }
    }
  }
}

output settings object = {
  profileName: cdnProfileName
  endpointName: cdnEndpointName
  url: cdnProfile::cdnEndpoint.properties.hostName
  originHostHeader: cdnProfile::cdnEndpoint.properties.originHostHeader
  originHostPath: cdnProfile::cdnEndpoint.properties.originPath
}
