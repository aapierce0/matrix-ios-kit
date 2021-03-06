/*
 Copyright 2015 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXKPushRuleCreationTableViewCell.h"

#import "NSBundle+MatrixKit.h"

@interface MXKPushRuleCreationTableViewCell ()
{
    /**
     Snapshot of matrix session rooms used in room picker (in case of MXPushRuleKindRoom)
     */
    NSArray* rooms;
}
@end

@implementation MXKPushRuleCreationTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.mxPushRuleKind = MXPushRuleKindContent;
}

- (void)setMxPushRuleKind:(MXPushRuleKind)mxPushRuleKind
{
    switch (mxPushRuleKind)
    {
        case MXPushRuleKindContent:
            _inputTextField.placeholder = [NSBundle mxk_localizedStringForKey:@"notification_settings_word_to_match"];
            _inputTextField.autocorrectionType = UITextAutocorrectionTypeDefault;
            break;
        case MXPushRuleKindRoom:
            _inputTextField.placeholder = [NSBundle mxk_localizedStringForKey:@"notification_settings_select_room"];
            break;
        case MXPushRuleKindSender:
            _inputTextField.placeholder = [NSBundle mxk_localizedStringForKey:@"notification_settings_sender_hint"];
            _inputTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            break;
        default:
            break;
    }
    
    _inputTextField.hidden = NO;
    _roomPicker.hidden = YES;
    _roomPickerDoneButton.hidden = YES;
    
    _mxPushRuleKind = mxPushRuleKind;
}

- (void)dismissKeyboard
{
    [_inputTextField resignFirstResponder];
}

#pragma mark - UITextField delegate

- (IBAction)textFieldEditingChanged:(id)sender
{
    // Update Add Room button
    if (_inputTextField.text.length)
    {
        _addButton.enabled = YES;
    }
    else
    {
        _addButton.enabled = NO;
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == _inputTextField && _mxPushRuleKind == MXPushRuleKindRoom)
    {
        _inputTextField.hidden = YES;
        _roomPicker.hidden = NO;
        _roomPickerDoneButton.hidden = NO;
        return NO;
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == _inputTextField && _mxPushRuleKind == MXPushRuleKindSender)
    {
        if (textField.text.length == 0)
        {
            textField.text = @"@";
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*) textField
{
    // "Done" key has been pressed
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender
{
    [self dismissKeyboard];
    
    if (sender == _addButton)
    {
        // Disable button to prevent multiple request
        _addButton.enabled = NO;
        
        if (_mxPushRuleKind == MXPushRuleKindContent)
        {
            [_mxSession.notificationCenter addContentRule:_inputTextField.text
                                                   notify:(_actionSegmentedControl.selectedSegmentIndex == 0)
                                                    sound:_soundSwitch.on
                                                highlight:_highlightSwitch.on];
        }
        else if (_mxPushRuleKind == MXPushRuleKindRoom)
        {
            MXRoom* room;
            NSInteger row = [_roomPicker selectedRowInComponent:0];
            if ((row >= 0) && (row < rooms.count))
            {
                room = [rooms objectAtIndex:row];
            }
            
            if (room)
            {
                [_mxSession.notificationCenter addRoomRule:room.state.roomId
                                                    notify:(_actionSegmentedControl.selectedSegmentIndex == 0)
                                                     sound:_soundSwitch.on
                                                 highlight:_highlightSwitch.on];
            }
            
        }
        else if (_mxPushRuleKind == MXPushRuleKindSender)
        {
            [_mxSession.notificationCenter addSenderRule:_inputTextField.text
                                                notify:(_actionSegmentedControl.selectedSegmentIndex == 0)
                                                 sound:_soundSwitch.on
                                             highlight:_highlightSwitch.on];
        }
        
        
        _inputTextField.text = nil;
    }
    else if (sender == _roomPickerDoneButton)
    {
        NSInteger row = [_roomPicker selectedRowInComponent:0];
        // sanity check
        if ((row >= 0) && (row < rooms.count))
        {
            MXRoom* room = [rooms objectAtIndex:row];
            _inputTextField.text = room.state.displayname;
            _addButton.enabled = YES;
        }
        
        _inputTextField.hidden = NO;
        _roomPicker.hidden = YES;
        _roomPickerDoneButton.hidden = YES;
    }
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    rooms = [_mxSession.rooms sortedArrayUsingComparator:^NSComparisonResult(MXRoom* firstRoom, MXRoom* secondRoom) {
        
        // Alphabetic order
        return [firstRoom.state.displayname compare:secondRoom.state.displayname options:NSCaseInsensitiveSearch];
    }];

    return rooms.count;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    MXRoom* room = [rooms objectAtIndex:row];
    return room.state.displayname;
}

@end
