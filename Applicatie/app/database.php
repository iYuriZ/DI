<?php

	function connectDatabase() {
		$serverHost = 'localhost';
		$databaseName = 'gelre_airport';

		$databaseUsername = 'sa';
		$databasePassword = '';

		try {
			$pdo = new PDO("sqlsrv:Server=$serverHost;Database=$databaseName", $databaseUsername, $databasePassword, [
				PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION // Dit is om PDO errors te weergeven
			]);

			return $pdo;
		} catch(PDOException $exception) {
			return $exception;
		}

		return false;
	}

	function getBalies() {

        $db = connectDatabase();

        

        try {
            $stmt = $db->prepare(
                'SELECT *
                FROM Balie'
            );
            $stmt->execute([

            ]);

            while ($row = $stmt->fetch()) {
                $highestBid = $row;
            }
        } catch (PDOException $e) {
            http_response_code(500);
            die();
        }
    }

?>