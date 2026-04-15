angular.module('Darkswarm').factory "UserService", ($http, spreeApiKey) ->
  new class UserService
    # Records that the current user has accepted the Terms of Service.
    # Called during enterprise registration when the user checks the ToS checkbox.
    acceptTermsOfService: =>
      $http(
        method: "POST"
        url: "/api/v0/users/accept_terms_of_service"
        params:
          token: spreeApiKey
      )
