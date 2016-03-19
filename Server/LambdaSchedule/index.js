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
			city: { S: event.city },
			state: { S: event.state },
			country: { S: event.country },
			lat: { S: event.lat },
			lon: { S: event.lon },
			type: { S: event.type },
			start: { N: event.start.toString() },
			from: { N: event.from.toString() },
			to: { N: event.to.toString() },
			at: { N: event.at.toString() },
			days: { N: event.days.toString() }
		},
		ConditionExpression: 'attribute_not_exists (sid)',
		ReturnValues: 'NONE'
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
								city: { Action: 'PUT', Value: { S: event.city } },
								state: { Action: 'PUT', Value: { S: event.state } },
								country: { Action: 'PUT', Value: { S: event.country } },
								lat: { Action: 'PUT', Value: { S: event.lat } },
								lon: { Action: 'PUT', Value: { S: event.lon } },
								type: { Action: 'PUT', Value: { S: event.type } },
								start: { Action: 'PUT', Value: { N: event.start.toString() } },
								from: { Action: 'PUT', Value: { N: event.from.toString() } },
								to: { Action: 'PUT', Value: { N: event.to.toString() } },
								at: { Action: 'PUT', Value: { N: event.at.toString() } },
								days: { Action: 'PUT', Value: { N: event.days.toString() } }
							  },
			ReturnValues: 'NONE'
		}, function(err, data) {
			if(err) callback(err, null);
			else callback(null, data);
		});
}

function removeSchedule(sid, callback) {
	dynamodb.deleteItem({
		TableName: config.DDB_SCHEDULE_TABLE,
		Key: { sid: { S: sid }},
		ReturnValues: 'NONE'
	}, function(err, data) {
		console.log(util.inspect(err, { showHidden: true, depth: 10 }));
		if(err) callback(err);
		else callback();
	});	
}

exports.handler = function(event, context) {
	console.log("event: " + util.inspect(event));

	if(event.action == "add") {		
		addSchedule(event, function(err, result) {
			if(err) context.fail({success:false, error:err});
			else context.succeed({success:true});
		});
	}
	else if(event.action == "update") {
		updateSchedule(event, function(err, result) {
			if(err) context.fail({success:false, error:err});
			else context.succeed({success:true});
		});
	}
	else if(event.action == "remove")
	{		
		updateSchedule(event, function(err) {
			if(err) context.fail({success:false, error:err});
			else context.succeed({success:true});
		});
	}
	else
	{
	    context.fail({success:false, error:'Invalid action: ' + event.action});		
	}
}
