<?php

	function connectDatabase() {
		$serverHost = 'localhost';
		$databaseName = 'gelre_airport';

		$databaseUsername = 'sa';
		$databasePassword = 'yuritess01';

		try {
			$pdo = new PDO("sqlsrv:Server=$serverHost;Database=$databaseName;ConnectionPooling=0", "$databaseUsername", "$databasePassword");
			$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

			return $pdo;
		} catch(PDOException $exception) {
			var_dump($exception);
            return $exception;
		}

		return false;
	}

?>