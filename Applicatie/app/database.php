<?php

	function connectDatabase() {
		$serverHost = 'localhost';
		$databaseName = 'gelre_airport';

		$databaseUsername = 'sa';
		$databasePassword = 'localhost';

		try {
			$pdo = new PDO("sqlsrv:Server=$serverHost;Database=$databaseName", $databaseUsername, $databasePassword, [
				PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION // Dit is om PDO errors te weergeven
			]);

			return $pdo;
		} catch(PDOException $exception) {
			var_dump($exception);
            return $exception;
		}

		return false;
	}

?>