/** 
 *  Copyright (c) 1999~2017, Altibase Corp. and/or its affiliates. All rights reserved.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License, version 3,
 *  as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
 
#include <rpdQueue.h>
#include <actTest.h>

void setXLog( rpdXLog * aXLog, acp_uint32_t aNumber )
{
    aXLog->mColCnt = aNumber;
    aXLog->mSN     = aNumber + 1;
}

/* unittest
 * rpdQueue::write(rpdXLog *aXLogPtr)
 * rpdQueue::read(rpdXLog **aXLogPtr)
 * rpdQueue::read(rpdXLog **aXLogPtr, UInt  aTimeoutSec)
 */
acp_sint32_t main( void )
{
    rpdQueue     sQueue;
    rpdXLog    * sPushXLog[3];
    rpdXLog    * sPopXLog;
    acp_uint32_t sCount;
    UInt         aTimeoutSec = 0;

    ACT_TEST_BEGIN();

    ACT_CHECK( iduMutexMgr::initializeStatic( IDU_CLIENT_TYPE ) == ACP_RC_SUCCESS );

    ACT_CHECK( sQueue.initialize( (char*)"REP_NAME" ) == ACP_RC_SUCCESS );

    /* insert datas to Queue
     * ( mColCnt, mSN ) : ( 100, 101 ) -> ( 200, 201 ) -> ( 300, 301 )
     */
    for ( sCount = 0; sCount < 3; sCount ++ )
    {
        ACT_CHECK( sQueue.allocXLog( &sPushXLog[sCount], NULL ) == ACP_RC_SUCCESS );
        setXLog( sPushXLog[sCount], ( sCount+1 ) * 100 );
        sQueue.write( sPushXLog[sCount] );
    }

    /* read(rpdXLog) function returns the first XLog */
    sQueue.read( &sPopXLog );
    ACT_CHECK( 100 == sPopXLog->mColCnt );
    ACT_CHECK( 101 == sPopXLog->mSN );

    /* read(rpdXLog, UInt) function returns the second XLog */
    sQueue.read( &sPopXLog, aTimeoutSec );
    ACT_CHECK( 200 == sPopXLog->mColCnt );
    ACT_CHECK( 201 == sPopXLog->mSN );

    /* read(rpdXLog) function returns the third XLog */
    sQueue.read( &sPopXLog );
    ACT_CHECK( 300 == sPopXLog->mColCnt );
    ACT_CHECK( 301 == sPopXLog->mSN );

    /* XLog's free is run inside destroy function. */
    sQueue.destroy();

    ACT_TEST_END();

    return 0;
}
