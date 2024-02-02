unit uXGsql;

interface

const

SQL_SEAT_INFO =
  'SELECT * FROM SEAT';

SQL_SEAT_UPDATE =
  'UPDATE seat SET ' +
               ' use_status = :use_status, ' +
               ' remain_minute = :remain_minute, ' +
               ' remain_ball = :Remain_balls ' +
  ' where store_cd = :store_cd ' +
  ' and seat_no = :teebox_no ';

implementation

end.
