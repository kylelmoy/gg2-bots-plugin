// botPolicyOnHandoverIn(player, char): PolicyController.OnHandoverIn - resync
// the decoder's absolute aim to where the character actually points. The
// scripted layer writes the bearing directly, so a decoder carrying the
// bearing from the last engagement would turn from somewhere nobody is
// pointing. netAimDirection is what botPoll last wrote (CharacterState
// .NetAimDirection).
argument0.botActionDecoderAim = argument1.netAimDirection * 360 / 65536;
