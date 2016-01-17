console.log('Loading function');

// dependencies
var AWS = require('aws-sdk');
var util = require('util');
var moment = require('moment');
var config = require('./config.json');

// Get reference to AWS clients
var dynamodb = new AWS.DynamoDB();

function addSchedule(event, callback) {
	var now = moment().utc().format('X');

	// Add DDB record
	dynamodb.putItem({
		TableName: config.DDB_SCHEDULE_TABLE,		
		Item: {
			sid: { S: event.sid },
			version: { N: event.version.toString() },
			created: { N: now },
			updated: { N: now },
			language: { S: event.language },
			user: { S: event.user },
			name: { S: event.name },
			avatar: {S: event.avatar },
			lat: { S: event.lat },
			lon: { S: event.lon },
			city: { S: event.city },
			state: { S: event.state },
			country: { S: event.country },
			start: { N: event.start.toString() }
		},
		ConditionExpression: 'attribute_not_exists (bid)',
		ReturnValues: 'ALL_OLD'
	}, function(err, data) {
		if(err) callback(err, null);
		else callback(null, data);
	});	
}

function updateSchedule(event, callback) {
		var now = moment().utc().format('X');

		// Update DDB record
		dynamodb.updateItem({
			TableName: config.DDB_SCHEDULE_TABLE,
			Key: { sid: { S: event.sid }},
			AttributeUpdates: { updated: { Action: 'PUT', Value: { N: now } },
								language: { Action: 'PUT', Value: { S: event.language } },
								user: { Action: 'PUT', Value: { S: event.user } },
								name: { Action: 'PUT', Value: { S: event.name } },
								avatar: { Action: 'PUT', Value: {S: event.avatar } },
								lat: { Action: 'PUT', Value: { S: event.lat } },
								lon: { Action: 'PUT', Value: { S: event.lon } },
								city: { Action: 'PUT', Value: { S: event.city } },
								state: { Action: 'PUT', Value: { S: event.state } },
								country: { Action: 'PUT', Value: { S: event.country } },
								start: { Action: 'PUT', Value: { N: event.start.toString() } }
							  },
			ReturnValues: 'ALL_NEW'
		}, function(err, data) {
			if(err) callback(err, null);
			else callback(null, data);
		});
}

/*
User Data
user
name
avatar URL
lat
lon
city
state
country

Schedule data

update - boolean
sid - schedule id
version
[user]
language
start timestamp
recurring

 */

exports.handler = function(event, context) {
	console.log("event: " + util.inspect(event));

	if(event.update) {
		updateSchedule(event, function(err, result) {
			if(err) context.fail(err);
			else context.succeed(result);
		});
	} else {		
		addSchedule(event, function(err, result) {
			if(err) context.fail(err);
			else context.succeed(result);
		});
	}
}
