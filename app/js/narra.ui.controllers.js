'use strict';

/*
 #
 # Copyright (C) 2013 CAS / FAMU
 #
 # This file is part of Narra UI.
 #
 # Narra UI is free software: you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
 # (at your option) any later version.
 #
 # Narra UI is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with Narra UI. If not, see <http://www.gnu.org/licenses/>.
 #
 # Authors: Michal Mocnak <michal@marigan.net>, Krystof Pesek <krystof.pesek@gmail.com>
 #
 */

// controllers
function DashboardCtrl($scope) {

}

function SystemSettingsCtrl($scope, service_Messages, api_Settings) {
    // refresh function
    $scope.refresh = function () {
        // get all settings and get back to view
        api_Settings.all(function (data) {
            $scope.settings = data.settings;
        });

        // get default values
        api_Settings.defaults(function (data) {
            $scope.defaults = data.defaults;
        });

        // default values
        $scope.cancel();
    }

    // set up editable flag for the single field
    $scope.edit = function (item) {
        $scope.editable = { name: item.name, value: item.value };
        $scope.resetable = !_.isEqual($scope.defaults[item.name], item.value);
    }

    $scope.$watch('editable.value', function (item) {
        if (!_.isNull(item)) {
            $scope.changed = !_.isEqual(_.find($scope.settings, {name: $scope.editable.name}).value, $scope.editable.value);
            $scope.resetable = !_.isEqual($scope.defaults[$scope.editable.name], $scope.editable.value);
        }
    });

    // reset editable flag
    $scope.cancel = function () {
        $scope.editable = null;
        $scope.changed = false;
        $scope.resetable = false;
    }

    $scope.default = function () {
        $scope.editable.value = $scope.defaults[$scope.editable.name];
    }

    // update values
    $scope.update = function () {
        api_Settings.update({name: String($scope.editable.name), value: String($scope.editable.value)}, function () {
            // update collection just for view
            $.grep($scope.settings, function (item) {
                if (_.isEqual(item.name, $scope.editable.name)) {
                    item.value = $scope.editable.value;
                }
            });

            // fire message
            service_Messages.send('success', 'Success!', 'Property ' + $scope.editable.name + ' was successfully updated.');

            // end up edit mode
            $scope.cancel();
        });
    }

    // initial data
    $scope.refresh();
}

function UsersCtrl($scope, $location, api_User) {
    // initial value
    $scope.empty = true;

    // refresh function
    $scope.refresh = function () {
        // get all projects and get back to view
        api_User.all(function (data) {
            $scope.users = data.users;
            $scope.empty = (data.users.length < 1);
        });
    }

    // detail user
    $scope.detail = function (user) {
        $location.path('/users/' + user.id);
    }

    // initial data
    $scope.refresh();
}

function UsersDetailCtrl($scope, $location, $routeParams, service_User, api_User, service_Messages ) {
    // if me
    $scope.me = _.isEqual($routeParams.id, 'me');

    // refresh function
    $scope.refresh = function () {
        // get user data
        if (!$scope.me) {
            api_User.get($scope.me ? {id: service_User.current().id} : {id: $routeParams.id}, function (data) {
                $scope.user = data.user;
                $scope.deletable = !_.isEqual(data.user, service_User.current());
            });
        } else {
            $scope.user = service_User.current();
            $scope.deletable = false;
        }
    };

    $scope.open = function () {
        $scope.shouldBeOpen = true;
    };

    $scope.close = function () {
        $scope.shouldBeOpen = false;
    };

    $scope.opts = {
        backdropFade: true,
        dialogFade: true
    };

    // delete user
    $scope.delete = function () {
        // close dialog
        $scope.close();
        // delete storage and its projects
        api_User.delete({id: $scope.user.id});
        // get back to the overview
        $location.path('/users');
        // fire alert
        service_Messages.send('success', 'Success!', 'User ' + $scope.user.name + ' was successfully deleted.');
    };

    // initial data
    $scope.refresh();
}

function ComponentsNavigationCtrl($scope, $location) {
    // Help function for selection identification
    $scope.selected = function (item) {
        return (_.isEqual($location.path(), item.url)) ? true : (_.isEqual(item.url, "/") ? false : $location.path().indexOf(item.url) > -1);
    }

    // navigation initial array
    $scope.navigation = [
        {name: "users", title: "Users", url: "/users", items: []},
        {name: "system", title: "System", url: "/system", items: [
            {name: "settings", title: "Settings", url: "/system/settings"}
        ]}
    ];
}

function ComponentsUserCtrl($scope, $rootScope, $window, api_User, service_User) {
    // refresh function
    $scope.refresh = function () {
        api_User.me(function (data) {
            if (data != null) {
                $scope.user = data.user;
                // fire user_auth
                $rootScope.$broadcast('event:auth_user', data.user);
            }
        });
    }

    // signout method
    $scope.signout = function () {
        // signout
        api_User.signout(function () {
            // redirect
            $window.location.href = '/';
        });
    }

    // initial data
    $scope.refresh();
}

function ComponentsLoginCtrl($scope, $window, api_Authentication) {
    $scope.opts = {
        backdrop: true,
        backdropFade: false,
        dialogFade: true,
        keyboard: false,
        backdropClick: false
    };

    $scope.open = function () {
        $scope.shouldBeOpen = true;
    };

    $scope.$on('event:auth_unauthenticated', function () {
        $scope.open();

        api_Authentication.active(function (data) {
            $window.location.href = 'http://api.narra.eu/auth/' + data.provider.name;
        });
    });
}

function ComponentsMessagesCtrl($scope, $timeout) {
    // initial alerts array
    $scope.alerts = [];

    $scope.close = function (index) {
        $scope.alerts.splice(index, 1);
    }

    $scope.push = function (alert) {
        $scope.alerts.push(alert);
    };

    $scope.$on('event:alert', function (event, alert) {
        // show alert
        $scope.push(alert);
        // set timer on close
        $timeout(function () {
            $scope.close($scope.alerts.indexOf(alert));
        }, 5000);
    });
}