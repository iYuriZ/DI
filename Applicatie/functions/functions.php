<?php

include 'app/database.php';

function getBalies(): array {


        $db = connectDatabase();

        $balies = [];

        try {
            $stmt = $db->query(
                'SELECT *
                FROM Balie'
            );

            while ($row = $stmt->fetch()) {
                array_push($balies, $row);
            }
        } catch (PDOException $e) {
            http_response_code(500);
            die();
        }

        return $balies;
    }
?>