#
# Copyright (C) 2014 CAS / FAMU
#
# This file is part of narra-ui.
#
# narra-ui is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# narra-ui is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with narra-ui. If not, see <http://www.gnu.org/licenses/>.
#
# Authors: Michal Mocnak <michal@marigan.net>
#

angular.module('narra.ui').controller 'LayoutsSequencePlayerWithContextCtrl', ($scope, $sce, $timeout, $routeParams, $window, $rootScope, $q, apiProject, apiVisualization, elzoidoPromises) ->
  # player
  $scope.player =
    api: undefined
    ready: false
    preload: true
    autoHide: true
    autoHideTime: 2000
    autoPlay: false
    sources: []
    playlist: []
    tracks: []
    cuePoints: {}
    plugins: {}

  $scope.refresh = ->
    # get deffered
    sequence = $q.defer()
    junctions = $q.defer()
    # get sequences
    apiProject.sequences {name: $scope.project.name, param: $scope.layout.options['sequence']}, (data) ->
      # get seauence
      $scope.sequence = data.sequence
      # temporary
      master_in = 0
      # process marks
      _.forEach($scope.sequence.marks, (mark) ->
        # get video source
        if _.isUndefined(mark.clip.source)
          if mark.clip.name == 'black'
            mark.clip.source = 'http://static.rur.cz/narra/black/black.mp4'
          else
            mark.clip.source = 'http://static.rur.cz/narra/bars/bars.mp4'
          mark.in = 0
          mark.out = mark.duration
        # set sequence in
        mark.master_in = master_in
        # iterate for the next
        master_in += mark.duration
      )
      # set playlist
      if _.isUndefined($scope.sequence.master)
        _.forEach($scope.sequence.marks, (mark) ->
          $scope.player.playlist.push({
            in: mark.in,
            out: mark.out,
            src: {src: $sce.trustAsResourceUrl(mark.clip.source), type: "video/mp4"}
          })
        )
      else
        $scope.player.playlist.push({
          in: 0,
          src: {src: $sce.trustAsResourceUrl($scope.sequence.master.source), type: "video/mp4"}
        })
      # get
      if !_.isUndefined($scope.layout.options['contextual_synthesizers'])
        $scope.context = { junctions: [], values: []}
        $scope.context.synthesizers = _.map($scope.layout.options['contextual_synthesizers'].split(','), (synthesizer) ->
          synthesizer.trim()
        )
        _.forEach($scope.context.synthesizers, (synthesizers, index) ->
          apiProject.junctions {name: $scope.project.name, param: synthesizers}, (data) ->
            $scope.context.junctions = $scope.context.junctions.concat(data.junctions)
            # check for last item
            if $scope.context.synthesizers.length == index + 1
              junctions.resolve true
        )
      else
        junctions.resolve true
      $scope.player.sources = [$scope.player.playlist[0].src]
      # resolve
      sequence.resolve true

    # register promises into one queue
    elzoidoPromises.register('sequence', [sequence.promise, junctions.promise])
    elzoidoPromises.promise('sequence').then ->
      # set first video
      $scope.player.current = 0
      # init player
      $scope.player.ready = true

  $scope.onPlayerReady = (api) ->
    # set player's api
    $scope.player.api = api
    # set first video seek time
    $timeout ->
      $scope.player.api.seekTime($scope.player.playlist[0].in)
    , 0

  $scope.playlistHandler = (currentTime) ->
    if _.isUndefined($scope.sequence.master)
      if currentTime >= $scope.player.playlist[$scope.player.current].out
        # set next video
        $scope.player.current += 1
        # refresh
        $scope.playerAction()
    else
      _.forEach($scope.sequence.marks, (mark, index) ->
        if currentTime > mark.master_in && ($scope.sequence.marks.length == index+1 || currentTime < $scope.sequence.marks[index+1].master_in)
          $scope.player.current = index
      )

  $scope.$watch 'player.current', ->
    if !_.isUndefined($scope.sequence) && !_.isUndefined($scope.context)
      # get mark
      mark = $scope.sequence.marks[$scope.player.current]
      # check if we have item
      if !_.isUndefined(mark.clip.id)
        if _.isUndefined($scope.context.values[$scope.player.current])
          $scope.context.values[$scope.player.current] = []
          selection = _.where($scope.context.junctions, {items: [{id: mark.clip.id}]})
          _.forEach(selection, (junction) ->
            _.forEach(junction.items, (item) ->
              if item.id != mark.clip.id
                $scope.context.values[$scope.player.current].push(item)
            )
          )

  $scope.isActive = (index) ->
    $scope.player.current == index

  $scope.playerAction = () ->
    if $scope.player.current != $scope.player.playlist.length
      $scope.player.sources = [$scope.player.playlist[$scope.player.current].src]
      $timeout ->
        $scope.player.api.seekTime($scope.player.playlist[$scope.player.current].in)
        $scope.player.api.play()
      , 0
    else
      $scope.player.api.stop()
      $scope.player.current = 0
      $scope.player.sources = [$scope.player.playlist[$scope.player.current].src]
      $timeout ->
        $scope.player.api.seekTime($scope.player.playlist[$scope.player.current].in)
      , 0

  $scope.playerStateChanged = (state) ->
    if state == 'play'
      # reset all context players
      $scope.contextPlayer = {}

  $scope.contextPlay = (item, index) ->
    # check for actual
    actual = !_.isUndefined($scope.contextPlayer) && !_.isUndefined($scope.contextPlayer[index])
    # switch all others off
    $scope.contextPlayer = {}
    # get source item
    if !actual
      apiProject.items {name: $scope.project.name, param: item.id}, (data) ->
        if data.item.type == 'video'
          # assign video
          $scope.contextPlayer[index] = [{ src: $sce.trustAsResourceUrl(data.item.video_proxy_hq), type: "video/mp4"}]
          # save a few more things
          author = _.find(data.item.metadata, {name: 'author'})
          if !_.isUndefined(author)
            item.author = author.value
          # stop main player
          $scope.player.api.pause()
    else
      $scope.player.api.play()

  $scope.refresh()