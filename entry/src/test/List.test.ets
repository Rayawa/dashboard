import discoveryTests from './Discovery.test';
import cacheTests from './Cache.test';
import localUnitTest from "./LocalUnit.test";

export default function testsuite() {
    localUnitTest();
    discoveryTests();
    cacheTests();
}
